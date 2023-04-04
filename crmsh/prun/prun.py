import os
import tempfile
import typing

import crmsh.constants
import crmsh.userdir
import crmsh.utils
from crmsh.prun.runner import Task, Runner


class ProcessResult:
    def __init__(self, returncode: int, stdout: bytes, stderr: bytes):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


class PRunError(Exception):
    def __init__(self, user, host, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.user = user
        self.host = host


class SSHError(PRunError):
    def __init__(self, user, host, msg):
        super().__init__(user, host, f"Cannot create SSH connection to {user}@{host}: {msg}")


def prun(host_cmdline: typing.Mapping[str, str]) -> typing.Dict[str, typing.Union[ProcessResult, SSHError]]:
    tasks = [_build_run_task(host, cmdline) for host, cmdline in host_cmdline.items()]
    runner = Runner()
    for task in tasks:
        runner.add_task(task)
    runner.run()
    return {
        task.context['host']: (
            ProcessResult(task.returncode, task.stdout, task.stderr) if task.returncode != 255
            else SSHError(task.context['ssh_user'], task.context['host'], crmsh.utils.to_ascii(task.stderr))
        )
        for task in tasks
    }


def _build_run_task(remote: str, cmdline: str) -> Task:
    local_sudoer, remote_sudoer = crmsh.utils.user_pair_for_ssh(remote)
    shell = 'ssh {} {}@{} sudo -H /bin/sh'.format(crmsh.constants.SSH_OPTION, remote_sudoer, remote)
    if local_sudoer == crmsh.userdir.getuser():
        args = ['/bin/sh', '-c', shell]
    elif os.geteuid() == 0:
        args = ['su', local_sudoer, '--login', '-c', shell]
    else:
        raise AssertionError('trying to run su as a non-root user')
    return Task(
        args,
        cmdline.encode('utf-8'),
        capture_stdout=True, capture_stderr=True,
        context={"host": remote, "ssh_user": remote_sudoer},
    )


def pcopy_to_remote(src: str, hosts: typing.Sequence[str], dst: str, recursive: bool = False) -> typing.Dict[str, typing.Optional[PRunError]]:
    """Copy file or directory from local to remote hosts concurrently."""
    flags = '-pr' if recursive else '-p'
    local_sudoer, _ = crmsh.utils.user_pair_for_ssh(hosts[0])
    script = "put {} '{}' '{}'\n".format(flags, src, dst)
    ssh = None
    try:
        ssh = tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False)
        os.fchmod(ssh.fileno(), 0o700)
        ssh.write(f'''#!/bin/sh
exec sudo -u {local_sudoer} ssh "$@"''')
        # It is necessary to close the file before executing
        ssh.close()
        tasks = [_build_copy_task("-S '{}'".format(ssh.name), script, host) for host in hosts]
        runner = Runner()
        for task in tasks:
            runner.add_task(task)
        runner.run()
    finally:
        if ssh is not None:
            os.unlink(ssh.name)
            ssh.close()
    return {task.context['host']: _parse_copy_result(task) for task in tasks}


def _build_copy_task(ssh: str, script: str, host: str):
    _, remote_sudoer = crmsh.utils.user_pair_for_ssh(host)
    cmd = "sftp {} {} -o BatchMode=yes -s 'sudo PATH=/usr/lib/ssh:/usr/libexec/ssh /bin/sh -c \"exec sftp-server\"' -b - {}@{}".format(
        ssh,
        crmsh.constants.SSH_OPTION,
        remote_sudoer, _enclose_inet6_addr(host),
    )
    return Task(
        ['/bin/sh', '-c', cmd],
        input=script.encode('utf-8'),
        capture_stdout=True,
        capture_stderr=True,
        inline_stderr=True,
        context={"host": host, "ssh_user": remote_sudoer},
    )


def _parse_copy_result(task: Task) -> typing.Optional[PRunError]:
    if task.returncode == 0:
        return None
    elif task.returncode == 255:
        return SSHError(task.context['ssh_user'], task.context['host'], crmsh.utils.to_ascii(task.stdout))
    else:
        return PRunError(task.context['ssh_user'], task.context['host'], crmsh.utils.to_ascii(task.stdout))


def _enclose_inet6_addr(addr: str):
    if ':' in addr:
        return f'[{addr}]'
    else:
        return addr
