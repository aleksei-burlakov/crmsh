@bootstrap
Feature: crmsh bootstrap process - options

  Test crmsh bootstrap options:
      "--node": Additional nodes to add to the created cluster
      "-i":      Bind to IP address on interface IF
      "-M":      Configure corosync with second heartbeat line
      "-n":      Set the name of the configured cluster
      "-A":      Configure IP address as an administration virtual IP
      "-u":      Configure corosync to communicate over unicast
      "-U":      Configure corosync to communicate over multicast
  Tag @clean means need to stop cluster service if the service is available
  Need nodes: hanode1 hanode2 hanode3

  @clean
  Scenario: Check help output
    When    Run "crm -h" on "hanode1"
    Then    Output is the same with expected "crm" help output
    When    Run "crm cluster init -h" on "hanode1"
    Then    Output is the same with expected "crm cluster init" help output
    When    Run "crm cluster join -h" on "hanode1"
    Then    Output is the same with expected "crm cluster join" help output
    When    Run "crm cluster remove -h" on "hanode1"
    Then    Output is the same with expected "crm cluster remove" help output
    When    Run "crm cluster geo_init -h" on "hanode1"
    Then    Output is the same with expected "crm cluster geo-init" help output
    When    Run "crm cluster geo_join -h" on "hanode1"
    Then    Output is the same with expected "crm cluster geo-join" help output
    When    Run "crm cluster geo_init_arbitrator -h" on "hanode1"
    Then    Output is the same with expected "crm cluster geo-init-arbitrator" help output
    When    Try "crm cluster init -i eth1 -i eth1 -y"
    Then    Except multiple lines
      """
      usage: init [options] [STAGE]
      crm: error: Duplicated input for '-i/--interface' option
      """
    When    Try "crm cluster init sbd -x -y" on "hanode1"
    Then    Expected "-x option or SKIP_CSYNC2_SYNC can't be used with any stage" in stderr
    When    Try "crm cluster init -i eth0 -i eth1 -i eth2 -y" on "hanode1"
    Then    Expected "Maximum number of interface is 2" in stderr
    When    Try "crm cluster init sbd -N hanode1 -N hanode2 -y" on "hanode1"
    Then    Expected "Can't use -N/--nodes option and stage(sbd) together" in stderr

  @clean
  Scenario: Stage validation
    When    Try "crm cluster init fdsf -y" on "hanode1"
    Then    Expected "Invalid stage: fdsf(available stages: ssh, csync2, corosync, sbd, cluster, ocfs2, admin, qdevice)" in stderr
    When    Try "crm cluster join fdsf -y" on "hanode1"
    Then    Expected "Invalid stage: fdsf(available stages: ssh, csync2, ssh_merge, cluster)" in stderr
    When    Try "crm cluster join ssh -y" on "hanode1"
    Then    Expected "Can't use stage(ssh) without specifying cluster node" in stderr

  @clean
  Scenario: Init whole cluster service on node "hanode1" using "--node" option
    Given   Cluster service is "stopped" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -y --node "hanode1 hanode2 hanode3"" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "started" on "hanode2"
    And     Online nodes are "hanode1 hanode2"
    And     Show cluster status on "hanode1"

    When    Try "crm cluster init cluster -y" on "hanode1"
    Then    Expected "Cluster is active, can't run 'cluster' stage" in stderr

  @clean
  Scenario: Bind specific network interface using "-i" option
    Given   Cluster service is "stopped" on "hanode1"
    And     IP "@hanode1.ip.0" is belong to "eth1"
    When    Run "crm cluster init -i eth1 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     IP "@hanode1.ip.0" is used by corosync on "hanode1"
    And     Show corosync ring status

  @clean
  Scenario: Using multiple network interface using "-M" option
    Given   Cluster service is "stopped" on "hanode1"
    And     IP "@hanode1.ip.default" is belong to "eth0"
    And     IP "@hanode1.ip.0" is belong to "eth1"
    When    Run "crm cluster init -M -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     IP "@hanode1.ip.default" is used by corosync on "hanode1"
    And     IP "@hanode1.ip.0" is used by corosync on "hanode1"
    And     Show corosync ring status
    And     Corosync working on "unicast" mode

  @clean
  Scenario: Using multiple network interface using "-i" option
    Given   Cluster service is "stopped" on "hanode1"
    And     IP "@hanode1.ip.default" is belong to "eth0"
    And     IP "@hanode1.ip.0" is belong to "eth1"
    When    Run "crm cluster init -i eth0 -i eth1 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     IP "@hanode1.ip.default" is used by corosync on "hanode1"
    And     IP "@hanode1.ip.0" is used by corosync on "hanode1"
    And     Show corosync ring status

  @clean
  Scenario: Setup cluster name and virtual IP using "-A" option
    Given   Cluster service is "stopped" on "hanode1"
    When    Try "crm cluster init -A xxx -y"
    Then    Except "ERROR: cluster.init: 'xxx' does not appear to be an IPv4 or IPv6 address"
    When    Try "crm cluster init -A @hanode1.ip.0 -y"
    Then    Except "ERROR: cluster.init: Address already in use: @hanode1.ip.0"
    When    Run "crm cluster init -n hatest -A @vip.0 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster name is "hatest"
    And     Cluster virtual IP is "@vip.0"
    And     Show cluster status on "hanode1"

    When    Try "crm cluster init cluster -y" on "hanode1"
    Then    Expected "Cluster is active, can't run 'cluster' stage" in stderr

  @clean
  Scenario: Init cluster service with udpu using "-u" option
    Given   Cluster service is "stopped" on "hanode1"
    When    Run "crm cluster init -u -y -i eth0" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster is using udpu transport mode
    And     IP "@hanode1.ip.default" is used by corosync on "hanode1"
    And     Show corosync ring status
    And     Corosync working on "unicast" mode

  @clean
  Scenario: Init cluster service with ipv6 using "-I" option
    Given   Cluster service is "stopped" on "hanode1"
    Given   Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -I -i eth1 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     IP "@hanode1.ip6.default" is used by corosync on "hanode1"
    When    Run "crm cluster join -c hanode1 -i eth1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     IP "@hanode2.ip6.default" is used by corosync on "hanode2"
    And     Corosync working on "unicast" mode

  @clean
  Scenario: Init cluster service with ipv6 unicast using "-I" and "-u" option
    Given   Cluster service is "stopped" on "hanode1"
    Given   Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -I -i eth1 -u -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     IP "@hanode1.ip6.default" is used by corosync on "hanode1"
    When    Run "crm cluster join -c hanode1 -i eth1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     IP "@hanode2.ip6.default" is used by corosync on "hanode2"
    And     Show cluster status on "hanode1"
    And     Corosync working on "unicast" mode

  @clean
  Scenario: Init cluster service with multicast using "-U" option (bsc#1132375)
    Given   Cluster service is "stopped" on "hanode1"
    Given   Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -U -i eth1 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    When    Run "crm cluster join -c hanode1 -i eth1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     Show cluster status on "hanode1"
    And     Corosync working on "multicast" mode

  @clean
  Scenario: Init cluster with -N option (bsc#1175863)
    Given   Cluster service is "stopped" on "hanode1"
    Given   Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -N hanode1 -N hanode2 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "started" on "hanode2"

  @clean
  Scenario: Skip using csync2 by -x option
    Given   Cluster service is "stopped" on "hanode1"
    Given   Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -y -x" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Service "csync2.socket" is "stopped" on "hanode1"
    When    Run "crm cluster join -c hanode1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     Service "csync2.socket" is "stopped" on "hanode2"
    When    Run "crm cluster init csync2 -y" on "hanode1"
    Then    Service "csync2.socket" is "started" on "hanode1"
    And     Service "csync2.socket" is "started" on "hanode2"
