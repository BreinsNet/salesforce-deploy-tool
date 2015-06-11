@push
Feature: Push code to salesforce

  As a developer
  I should be able to push code to a sandbox

  Scenario: Push code to a sandbox
    When I run `sf push`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https:\/\/test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a different sandbox
    When I run `sf push -s testEnvAlt`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnvAlt using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnvAlt:.*OK$
    """

  Scenario: Push code to production should use the url login.salesorce.com
    When I run `sf push -s prod`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from prod using url https://login.salesforce.com to temporary directory to generate destructiveChanges.xml.*$
    """
  Scenario: Push code to a sandbox with debug information
    When I run `sf push -d`
    Then the exit status should be 0
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match /^.* testEnv .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*deployCode.*BUILD SUCCESSFUL.*$/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist

  Scenario: Push code to a sandbox with debug information to a different sandbox
    When I run `sf push -d -s testEnvAlt`
    Then the exit status should be 0
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match /^.* testEnvAlt .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*BUILD SUCCESSFUL.*$/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist

  Scenario: Push code to a sandbox and trigger all the tests
    When I run `sf push -T`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /runAllTests.*true/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying and Testing code to testEnv:.*OK$
    """
  Scenario: Push code to a sandbox and trigger all the tests in debug mode
    When I run `sf push -T -d`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /runAllTests.*true/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the output should match /^.* testEnv .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*Running Test:.*DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL.*$/

  Scenario: Push code to a sandbox in append mode
    When I run `sf push -a`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox in append mode and run all tests
    When I run `sf push -a -T`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /runAllTests.*true/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying and Testing code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox in append mode and run all tests and output debug information
    When I run `sf push -a -T -d`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /runAllTests.*true/
    And a file named "repo/salesforce/src/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying and Testing code to testEnv:  $
    ^$
    ^Buildfile: .*$
    ^$
    ^deployAndTestCode:$
    """
    And the output should match /Running Test/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  @test
  Scenario: Push code to a sandbox with a build number
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_VERSION_FILE         | classes/VersionTest.cls |
      | SFDT_BUILD_NUMBER_PATTERN | %%BUILD_NUMBER%%        |
    When I watch "repo/salesforce/src/classes/VersionTest.cls" for changes and copy to "test_file"
    And I run `sf push --build_number 123456789`
    Then the exit status should be 0
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "test_file" should contain "123456789"
    And the file "repo/salesforce/src/classes/VersionTest.cls" should contain "%%BUILD_NUMBER%%"
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox with the commit hash stamped into a version file
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_VERSION_FILE         | classes/VersionTest.cls |
      | SFDT_COMMIT_HASH_PATTERN  | %%COMMIT_HASH%%        |
    When I watch "repo/salesforce/src/classes/VersionTest.cls" for changes and copy to "test_file"
    And I run `sf push`
    Then the exit status should be 0
    And the file "test_file" should contain "aac66ee0d404c124fbcafd32a054664de4fdd3da"
    And the file "repo/salesforce/src/classes/VersionTest.cls" should contain "%%COMMIT_HASH%%"
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox with the repo not being cloned it should point the user to run sf config
    When I delete the repository directory
    And I run `sf push -d`
    Then the exit status should be 1
    And the output should match:
    """
    ^ERROR: The source directory .* is not a valid salesforce source directory
    """

  Scenario: Push code to a sandbox specifying a different URL
    Given I set the environment variables to:
      | variable             | value                                                   |
      | SFDT_SALESFORCE_URL  | https://invalid_url.salesforce.com |
    When I run `sf push -d`
    Then the exit status should be 1
    And the output should match:
    """
    .*Failed to login: Failed to send request to https://invalid_url.salesforce.com.*
    """

  Scenario: Push code to a sandbox and trigger individual tests in debug mode
    When I run `sf push -r individual_test -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /testLevel.*RunSpecifiedTests/
    And the file "/tmp/sfdt-test/build.xml" should match /runTest/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying and Testing code to testEnv:  $
    ^$
    ^Buildfile: .*$
    ^$
    ^deployAndRunSpecifiedTests:$
    """
    And the output should match /Running Test/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox with a build number
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_VERSION_FILE         | classes/VersionTest.cls |
      | SFDT_BUILD_NUMBER_PATTERN | %%BUILD_NUMBER%%        |
    When I watch "repo/salesforce/src/classes/VersionTest.cls" for changes and copy to "test_file"
    And I run `sf push --build_number 123456789`
    Then the exit status should be 0
    And the file "test_file" should contain "123456789"
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/classes/VersionTest.cls" should contain "%%BUILD_NUMBER%%"
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox with the commit hash stamped into a version file
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_VERSION_FILE         | classes/VersionTest.cls |
      | SFDT_COMMIT_HASH_PATTERN  | %%COMMIT_HASH%%        |
    When I watch "repo/salesforce/src/classes/VersionTest.cls" for changes and copy to "test_file"
    And I run `sf push`
    Then the exit status should be 0
    And the file "test_file" should contain "aac66ee0d404c124fbcafd32a054664de4fdd3da"
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/classes/VersionTest.cls" should contain "%%COMMIT_HASH%%"
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Pulling changes from testEnv using url https://test.salesforce.com to temporary directory to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to testEnv:.*OK$
    """

  Scenario: Push code to a sandbox with the repo not being cloned it should point the user to run sf config
    When I delete the repository directory
    And I run `sf push -d`
    Then the exit status should be 1
    And the output should match:
    """
    ^ERROR: The source directory .* is not a valid salesforce source directory
    """

  Scenario: Push code to a sandbox specifying a different URL
    Given I set the environment variables to:
      | variable             | value                                                   |
      | SFDT_SALESFORCE_URL  | https://invalid_url.salesforce.com |
    When I run `sf push -d`
    Then the exit status should be 1
    And the output should match:
    """
    .*Failed to login: Failed to send request to https://invalid_url.salesforce.com.*
    """
  Scenario: Push code to a sandbox and trigger individual tests in debug mode
    When I run `sf push -r individual_test -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /testLevel.*RunSpecifiedTests/
    And the file "/tmp/sfdt-test/build.xml" should match /runTest/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying and Testing code to testEnv:  $
    ^$
    ^Buildfile: .*$
    ^$
    ^deployAndRunSpecifiedTests:$
    """
    And the output should match /Running Test: .*/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox in check only mode using debug and Test
    When I run `sf push -c -d -T`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /checkOnly.*true/
    And the file "/tmp/sfdt-test/build.xml" should match /runAllTests.*true/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying and Testing code to testEnv:.*$
    ^$
    ^Buildfile: .*$
    ^$
    ^checkAndTestCode:$
    """
    And the output should match /Running Test/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox in check only mode using debug
    When I run `sf push -c -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "/tmp/sfdt-test/build.xml" should match /checkOnly.*true/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying code to testEnv:.*$
    ^$
    ^Buildfile: .*$
    ^$
    ^checkCode:$
    """
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox in debug mode and exclude specific metadata objects to exclude
    When I run `sf push -e Account.Sort__c -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the output should match /Pulling.*testEnv.*https:..test.salesforce.com.*destructiveChanges.xml/
    And the output should match /excluded: Account.Sort__c/
    And the output should match /INFO: Deploying code to testEnv/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox in debug mode and specifieng specific metadata to destroy
    When I run `sf push -i apexclass -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should contain "ApexClass"
    And the file "repo/salesforce/src/destructiveChanges.xml" should not contain "ApexPage"
    And the output should match /Pulling.*testEnv.*https:..test.salesforce.com.*destructiveChanges.xml/
    And the output should match /included: apexclass/
    And the output should match /INFO: Deploying code to testEnv/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox in debug mode and specifieng specific metadata exclude from destructive change
    When I run `sf push -e NewVersionTest -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should not contain "ApexClass"
    And the file "repo/salesforce/src/destructiveChanges.xml" should not contain "NewVersionTest"
    And the file "repo/salesforce/src/destructiveChanges.xml" should contain "ApexPage"
    And the output should match /Pulling.*testEnv.*https:..test.salesforce.com.*destructiveChanges.xml/
    And the output should match /excluded: NewVersionTest/
    And the output should match /INFO: Deploying code to testEnv/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  @ant
  Scenario: Push code to a sandbox using a different ant library path in debug mode should show the library path in the output
    Given I set the environment variables to:
      | variable                  | value                   |
      | SFDT_ANT_LIB              | lib/ant34.jar           |
    When I run `sf push -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying code to .*$
    ^$
    ^AntLibraryFile: .*lib/ant34.jar$
    ^Buildfile: .*$
    ^$
    ^deployCode:$
    """

  @ant
  Scenario: Push code to a sandbox using a different ant library path in debug mode should show the library path in the output
    When I run `sf push -l lib/ant34.jar -d`
    Then the exit status should be 0
    And a file named "repo/salesforce/src/destructiveChanges.xml" should exist
    And the file "/tmp/sfdt-test/build.xml" should match /sf:deploy/
    And the file "repo/salesforce/src/destructiveChanges.xml" should match /ApexClass|ApexPage/
    And the output should match:
    """
    ^INFO: Deploying code to .*$
    ^$
    ^AntLibraryFile: .*lib/ant34.jar$
    ^Buildfile: .*$
    ^$
    ^deployCode:$
    """

  @ant
  Scenario: Push code to a sandbox using a invalid ant library path should fail
    When I run `sf push -l lib/invalid_ant34.jar`
    Then the exit status should be 1
    And the output should match:
    """
    ^error: ant library file .* not found$
    """
