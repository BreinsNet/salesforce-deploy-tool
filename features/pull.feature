@pull
Feature: Pull code from salesforce

  As a developer
  I want to be able to retrieve code from a sandbox

  Scenario: Retrieve code from the default sandbox
    When I run `sf pull`
    Then the exit status should be 0
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*OK
    """

  Scenario: Retrieve code from a specific sandbox
    When I run `sf pull -s testEnvAlt`
    Then the exit status should be 0
    And the output should match:
    """
    ^INFO: Pulling changes from testEnvAlt using url https://test.salesforce.com.*OK
    """

  Scenario: Retrieve code from a sandbox using a specific URL
    Given I set the environment variables to:
      | variable             | value                                                   |
      | SFDT_SALESFORCE_URL  | https://invalid_url.salesforce.com |
    When I run `sf pull`
    Then the exit status should be 1
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://invalid_url.*
    """

  Scenario: Retrieve code from a production
    When I run `sf pull -s prod`
    Then the exit status should be 0
    And the output should match:
    """
    ^INFO: Pulling changes from prod using url https://login.salesforce.com.*OK$
    """

  Scenario: Retrieve code from the default sandbox with debug output
    When I run `sf pull -d`
    Then the exit status should be 0
    And the output should contain "BUILD SUCCESSFUL"
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*
    """

  Scenario: Retrieve code from a specific sandbox with debug output
    When I run `sf pull -s testEnv -d`
    Then the exit status should be 0
    And the output should contain "BUILD SUCCESSFUL"
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*$
    """

