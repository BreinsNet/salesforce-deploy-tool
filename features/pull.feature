@pull
Feature: Pull code from salesforce

  As a developer
  I want to be able to retrieve code from a sandbox
  
  Scenario: Retrieve code from the default sandbox
    When I run `sf pull`
    Then the exit status should be 0
    And the output should match /INFO: Pulling changes from env_a.*OK/

  Scenario: Retrieve code from a specific sandbox
    When I run `sf pull -s env_b`
    Then the exit status should be 0
    And the output should match /INFO: Pulling changes from env_b.*OK/

  Scenario: Retrieve code from the default sandbox with debug output
    When I run `sf pull -d`
    Then the exit status should be 0
    And the output should contain "INFO: Pulling changes from env_a"
    And the output should contain "BUILD SUCCESSFUL"

  Scenario: Retrieve code from a specific sandbox with debug output
    When I run `sf pull -s env_a -d`
    Then the exit status should be 0
    And the output should contain "INFO: Pulling changes from env_a"
    And the output should contain "BUILD SUCCESSFUL"

