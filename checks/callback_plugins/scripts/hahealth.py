#!/usr/bin/python3
import os
import callback_plugins.scripts.crm_script as crm

try:
    import json
except ImportError:
    import simplejson as json

def get_from_date():
    rc, out, err = crm.call("date '+%F %H:%M' --date='1 day ago'", shell=True)
    return out.strip()

def create_report():
    cmd = ['crm', 'report',
           '-f', get_from_date(),
           '-Z', 'health-report']
    rc, out, err = crm.call(cmd, shell=False)
    return rc == 0

def extract_report():
    rc, out, err = crm.call(['tar', 'xzf', 'health-report.tar.gz'], shell=False)
    return rc == 0

def do_hahealth():
    if not os.path.isfile('/usr/sbin/crm') and not os.path.isfile('/usr/bin/crm'):
        # crm not installed
        crm.exit_ok({'status': 'crm not installed'})

    if not create_report():
        crm.exit_ok({'status': 'Failed to create report'})

    if not extract_report():
        crm.exit_ok({'status': 'Failed to extract report'})

    analysis = ''
    if os.path.isfile('health-report/analysis.txt'):
        analysis = open('health-report/analysis.txt').read()

    print(json.dumps({'status': 'OK', 'analysis': analysis}))
