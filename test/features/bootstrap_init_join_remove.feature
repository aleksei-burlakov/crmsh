@bootstrap
Feature: crmsh bootstrap process - init, join and remove

  Test crmsh bootstrap init/join/remove process
  Need nodes: hanode1 hanode2 hanode3

  Background: Setup a two nodes cluster
    Given   Nodes ["hanode1", "hanode2", "hanode3"] are cleaned up
    And     Cluster service is "stopped" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Show cluster status on "hanode1"
    When    Run "crm cluster join -c hanode1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     Online nodes are "hanode1 hanode2"
    And     Show cluster status on "hanode1"

  Scenario: Init cluster service on node "hanode1", and join on node "hanode2"

  Scenario: Support --all or specific node to manage cluster and nodes
    When    Run "crm node standby --all" on "hanode1"
    Then    Node "hanode1" is standby
    And     Node "hanode2" is standby
    When    Run "crm node online --all" on "hanode1"
    Then    Node "hanode1" is online
    And     Node "hanode2" is online
    When    Wait for DC
    When    Run "crm cluster stop --all" on "hanode1"
    Then    Cluster service is "stopped" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster start --all" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "started" on "hanode2"
    When    Wait for DC
    When    Run "crm cluster stop hanode2" on "hanode1"
    Then    Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster start hanode2" on "hanode1"
    Then    Cluster service is "started" on "hanode2"
    When    Run "crm cluster disable hanode2" on "hanode1"
    Then    Cluster service is "disabled" on "hanode2"
    When    Run "crm cluster enable hanode2" on "hanode1"
    Then    Cluster service is "enabled" on "hanode2"
    When    Run "crm cluster restart --all" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "started" on "hanode2"

  Scenario: Remove peer node "hanode2"
    When    Run "crm configure primitive d1 Dummy" on "hanode1"
    When    Run "crm configure primitive d2 Dummy" on "hanode2"
    Then    File "/etc/csync2/csync2.cfg" exists on "hanode2"
    Then    File "/etc/csync2/key_hagroup" exists on "hanode2"
    Then    File "/etc/corosync/authkey" exists on "hanode2"
    Then    File "/etc/corosync/corosync.conf" exists on "hanode2"
    Then    File "/etc/pacemaker/authkey" exists on "hanode2"
    Then    Directory "/var/lib/csync2/" not empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/cib/" not empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/pengine/" not empty on "hanode2"
    Then    Directory "/var/lib/corosync/" not empty on "hanode2"
    When    Run "crm cluster remove hanode2 -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    And     Online nodes are "hanode1"
    And     Show cluster status on "hanode1"
    Then    File "/etc/csync2/csync2.cfg" not exist on "hanode2"
    Then    File "/etc/csync2/key_hagroup" not exist on "hanode2"
    Then    File "/etc/corosync/authkey" not exist on "hanode2"
    Then    File "/etc/corosync/corosync.conf" not exist on "hanode2"
    Then    File "/etc/pacemaker/authkey" not exist on "hanode2"
    Then    Directory "/var/lib/csync2/" is empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/cib/" is empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/pengine/" is empty on "hanode2"
    Then    Directory "/var/lib/corosync/" is empty on "hanode2"

  Scenario: Remove local node "hanode1"
    When    Run "crm configure primitive d1 Dummy" on "hanode1"
    When    Run "crm configure primitive d2 Dummy" on "hanode1"
    Then    File "/etc/csync2/csync2.cfg" exists on "hanode1"
    Then    File "/etc/csync2/key_hagroup" exists on "hanode1"
    Then    File "/etc/corosync/authkey" exists on "hanode1"
    Then    File "/etc/corosync/corosync.conf" exists on "hanode1"
    Then    File "/etc/pacemaker/authkey" exists on "hanode1"
    Then    Directory "/var/lib/csync2/" not empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/cib/" not empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/pengine/" not empty on "hanode1"
    Then    Directory "/var/lib/corosync/" not empty on "hanode1"
    When    Run "crm cluster remove hanode1 -y --force" on "hanode1"
    Then    Cluster service is "stopped" on "hanode1"
    And     Cluster service is "started" on "hanode2"
    And     Show cluster status on "hanode2"
    Then    File "/etc/csync2/csync2.cfg" not exist on "hanode1"
    Then    File "/etc/csync2/key_hagroup" not exist on "hanode1"
    Then    File "/etc/corosync/authkey" not exist on "hanode1"
    Then    File "/etc/corosync/corosync.conf" not exist on "hanode1"
    Then    File "/etc/pacemaker/authkey" not exist on "hanode1"
    Then    Directory "/var/lib/csync2/" is empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/cib/" is empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/pengine/" is empty on "hanode1"
    Then    Directory "/var/lib/corosync/" is empty on "hanode1"

  Scenario: Remove peer node "hanode2" with `crm -F node delete`
    When    Run "crm configure primitive d1 Dummy" on "hanode1"
    When    Run "crm configure primitive d2 Dummy" on "hanode2"
    Then    File "/etc/csync2/csync2.cfg" exists on "hanode2"
    Then    File "/etc/csync2/key_hagroup" exists on "hanode2"
    Then    File "/etc/corosync/authkey" exists on "hanode2"
    Then    File "/etc/corosync/corosync.conf" exists on "hanode2"
    Then    File "/etc/pacemaker/authkey" exists on "hanode2"
    Then    Directory "/var/lib/csync2/" not empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/cib/" not empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/pengine/" not empty on "hanode2"
    Then    Directory "/var/lib/corosync/" not empty on "hanode2"
    When    Run "crm -F cluster remove hanode2" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    And     Online nodes are "hanode1"
    And     Show cluster status on "hanode1"
    Then    File "/etc/csync2/csync2.cfg" not exist on "hanode2"
    Then    File "/etc/csync2/key_hagroup" not exist on "hanode2"
    Then    File "/etc/corosync/authkey" not exist on "hanode2"
    Then    File "/etc/corosync/corosync.conf" not exist on "hanode2"
    Then    File "/etc/pacemaker/authkey" not exist on "hanode2"
    Then    Directory "/var/lib/csync2/" is empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/cib/" is empty on "hanode2"
    Then    Directory "/var/lib/pacemaker/pengine/" is empty on "hanode2"
    Then    Directory "/var/lib/corosync/" is empty on "hanode2"
    When    Run "crm cluster remove hanode1 -y --force" on "hanode1"
    Then    File "/etc/corosync/corosync.conf" not exist on "hanode1"

  Scenario: Remove local node "hanode1" with `crm -F node delete`
    When    Run "crm configure primitive d1 Dummy" on "hanode1"
    When    Run "crm configure primitive d2 Dummy" on "hanode1"
    Then    File "/etc/csync2/csync2.cfg" exists on "hanode1"
    Then    File "/etc/csync2/key_hagroup" exists on "hanode1"
    Then    File "/etc/corosync/authkey" exists on "hanode1"
    Then    File "/etc/corosync/corosync.conf" exists on "hanode1"
    Then    File "/etc/pacemaker/authkey" exists on "hanode1"
    Then    Directory "/var/lib/csync2/" not empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/cib/" not empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/pengine/" not empty on "hanode1"
    Then    Directory "/var/lib/corosync/" not empty on "hanode1"
    When    Run "crm -F node delete hanode1" on "hanode1"
    Then    Cluster service is "stopped" on "hanode1"
    And     Cluster service is "started" on "hanode2"
    And     Show cluster status on "hanode2"
    Then    File "/etc/csync2/csync2.cfg" not exist on "hanode1"
    Then    File "/etc/csync2/key_hagroup" not exist on "hanode1"
    Then    File "/etc/corosync/authkey" not exist on "hanode1"
    Then    File "/etc/corosync/corosync.conf" not exist on "hanode1"
    Then    File "/etc/pacemaker/authkey" not exist on "hanode1"
    Then    Directory "/var/lib/csync2/" is empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/cib/" is empty on "hanode1"
    Then    Directory "/var/lib/pacemaker/pengine/" is empty on "hanode1"
    Then    Directory "/var/lib/corosync/" is empty on "hanode1"

  Scenario: Check hacluster's passwordless configuration on 2 nodes
    Then    Check user shell for hacluster between "hanode1 hanode2"
    Then    Check passwordless for hacluster between "hanode1 hanode2"

  Scenario: Check hacluster's passwordless configuration in old cluster, 2 nodes
    When    Run "crm cluster stop --all" on "hanode1"
    Then    Cluster service is "stopped" on "hanode1"
    And     Cluster service is "stopped" on "hanode2"
    When    Run "crm cluster init -y" on "hanode1"
    Then    Cluster service is "started" on "hanode1"
    When    Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode1"
    When    Run "crm cluster join -c hanode1 -y" on "hanode2"
    Then    Cluster service is "started" on "hanode2"
    And     Online nodes are "hanode1 hanode2"
    And     Check passwordless for hacluster between "hanode1 hanode2"

  Scenario: Check hacluster's passwordless configuration on 3 nodes
    Given   Cluster service is "stopped" on "hanode3"
    When    Run "crm cluster join -c hanode1 -y" on "hanode3"
    Then    Cluster service is "started" on "hanode3"
    And     Online nodes are "hanode1 hanode2 hanode3"
    And     Check user shell for hacluster between "hanode1 hanode2 hanode3"
    And     Check passwordless for hacluster between "hanode1 hanode2 hanode3"

  Scenario: Check hacluster's passwordless configuration in old cluster, 3 nodes
    Given   Cluster service is "stopped" on "hanode3"
    When    Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode1"
    And     Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode2"
    When    Run "crm cluster join -c hanode1 -y" on "hanode3"
    Then    Cluster service is "started" on "hanode3"
    And     Online nodes are "hanode1 hanode2 hanode3"
    And     Check passwordless for hacluster between "hanode1 hanode2 hanode3"

  Scenario: Check hacluster's user shell
    Given   Cluster service is "stopped" on "hanode3"
    When    Run "crm cluster join -c hanode1 -y" on "hanode3"
    Then    Cluster service is "started" on "hanode3"
    And     Online nodes are "hanode1 hanode2 hanode3"
    When    Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode1"
    And     Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode2"
    And     Run "rm -rf /var/lib/heartbeat/cores/hacluster/.ssh" on "hanode3"
    And     Run "usermod -s /usr/sbin/nologin hacluster" on "hanode1"
    And     Run "usermod -s /usr/sbin/nologin hacluster" on "hanode2"
    And     Run "usermod -s /usr/sbin/nologin hacluster" on "hanode3"
    And     Run "rm -f /var/lib/crmsh/upgrade_seq" on "hanode1"
    And     Run "rm -f /var/lib/crmsh/upgrade_seq" on "hanode2"
    And     Run "rm -f /var/lib/crmsh/upgrade_seq" on "hanode3"
    And     Run "crm status" on "hanode1"
    Then    Check user shell for hacluster between "hanode1 hanode2 hanode3"
    Then    Check passwordless for hacluster between "hanode1 hanode2 hanode3"
