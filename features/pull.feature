@pull
Feature: Pull code from salesforce

  As a developer
  I want to be able to retrieve code from a sandbox

  Scenario: Retrieve code from the default sandbox
    When I run `sf pull`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the file "/tmp/sfdt-test/build.xml" should match /retrieveTarget/
    And the file "/tmp/sfdt-test/build.xml" should match /unpackaged/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*OK
    """

  Scenario: Retrieve code from a specific sandbox
    When I run `sf pull -s testEnvAlt`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
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
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://invalid_url.*
    """

  Scenario: Retrieve code from a production
    When I run `sf pull -s prod`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should match:
    """
    ^INFO: Pulling changes from prod using url https://login.salesforce.com.*OK$
    """

  Scenario: Retrieve code from the default sandbox with debug output
    When I run `sf pull -d`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should contain "BUILD SUCCESSFUL"
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*
    """

  Scenario: Retrieve code from a specific sandbox with debug output
    When I run `sf pull -s testEnv -d`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should contain "BUILD SUCCESSFUL"
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com.*$
    """

  Scenario: Retrieve code from the default sandbox with debug output and specifying ant library path
    When I run `sf pull -d -l lib/ant34.jar`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com  $
    ^$
    ^AntLibraryFile: .*lib/ant34.jar$
    ^Buildfile: .*$
    ^$
    ^retrieveCode:$
    """

  Scenario: Retrieve code from the default sandbox with debug output and specifying ant library path
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_ANT_LIB              | lib/ant34.jar           |
    When I run `sf pull -d`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:retrieve/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com  $
    ^$
    ^AntLibraryFile: .*lib/ant34.jar$
    ^Buildfile: .*$
    ^$
    ^retrieveCode:$
    """

  Scenario: Retrieve code from the default sandbox with debug output and specifying a wrong ant library path
    When I run `sf pull -d -l lib/invalid_ant34.jar`
    Then the exit status should be 1
    And the output should match:
    """
    ^error: ant library file .* not found$
    """

  Scenario: Pull code from a sandbox using a invalid parameter sequence should fail
    When I run `sf pull -s -d prod`
    Then the exit status should be 1
    And the output should match:
    """
    ^invalid sandbox name .*. Please use a valid sandbox name$
    """
