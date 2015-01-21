@push
Feature: Push code to salesforce

  As a developer
  I should be able to push code to a sandbox

  Scenario: Push code to a sandbox
    When I run `sf push`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should exist
    And the output should match:
    """
    ^INFO: Pulling changes from env_a to temporary directory .*tmp_repo.* to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to env_a:.*OK$
    """

  Scenario: Push code to a different sandbox
    When I run `sf push -s env_b`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should exist
    And the output should match:
    """
    ^INFO: Pulling changes from env_b to temporary directory .*tmp_repo.* to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to env_b:.*OK$
    """

  Scenario: Push code to a sandbox with debug information
    When I run `sf push -d`
    Then the exit status should be 0
    And the output should match /^.* env_a .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*BUILD SUCCESSFUL.*$/
    And a file named "dcxml_location/destructiveChanges.xml" should exist

  Scenario: Push code to a sandbox with debug information to a different sandbox
    When I run `sf push -d -s env_b`
    Then the exit status should be 0
    And the output should match /^.* env_b .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*BUILD SUCCESSFUL.*$/
    And a file named "dcxml_location/destructiveChanges.xml" should exist

  Scenario: Push code to a sandbox and trigger all the tests
    When I run `sf push -T`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should exist
    And the output should match:
    """
    ^INFO: Pulling changes from env_a to temporary directory .*tmp_repo.* to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying and Testing code to env_a:.*OK$
    """

  Scenario: Push code to a sandbox and trigger all the tests in debug mode
    When I run `sf push -T -d`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should exist
    And the output should match /^.* env_a .*BUILD SUCCESSFUL.*Diff between.*Changes detected.*File generated.*Running Test:.*DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL.*$/

  Scenario: Push code to a sandbox in append mode
    When I run `sf push -a`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying code to env_a:.*OK$
    """

  Scenario: Push code to a sandbox in append mode and run all tests
    When I run `sf push -a -T`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying and Testing code to env_a:.*OK$
    """

  Scenario: Push code to a sandbox in append mode and run all tests and output debug information
    When I run `sf push -a -T -d`
    Then the exit status should be 0
    And a file named "dcxml_location/destructiveChanges.xml" should not exist
    And the output should match:
    """
    ^INFO: Deploying and Testing code to env_a:  $
    ^$
    ^Buildfile: .*$
    ^$
    ^deployAndTestCode:$
    """
    And the output should match /Running Test/
    And the output should match /DEPLOYMENT SUCCEEDED.*BUILD SUCCESSFUL/

  Scenario: Push code to a sandbox with a build number
    Given I set the environment variables to:
      | variable                  | value                |
      | SFDT_VERSION_FILE         | version_file         |
      | SFDT_BUILD_NUMBER_PATTERN | build_number_pattern |
    When I watch "sfdt_git_dir/version_file" for changes and copy to "test_file"
    And I run `sf push --build_number 123456789`
    Then the exit status should be 0
    And the file "test_file" should contain "123456789"
    And the file "sfdt_git_dir/version_file" should contain "build_number_pattern"
    And the output should match:
    """
    ^INFO: Pulling changes from env_a to temporary directory .*tmp_repo.* to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to env_a:.*OK$
    """

  Scenario: Push code to a sandbox with the commit hash stamped into a version file
    Given I set the environment variables to:
      | variable                  | value                |
      | SFDT_VERSION_FILE         | version_file         |
      | SFDT_COMMIT_HASH_PATTERN  | commit_hash_pattern  |
    When I watch "sfdt_git_dir/version_file" for changes and copy to "test_file"
    And I run `sf push`
    Then the exit status should be 0
    And the file "test_file" should not contain "commit_hash_pattern"
    And the file "sfdt_git_dir/version_file" should contain "commit_hash_pattern"
    And the output should match:
    """
    ^INFO: Pulling changes from env_a to temporary directory .*tmp_repo.* to generate destructiveChanges.xml.*OK$
    ^INFO: Creating destructive changes xml$
    ^INFO: Deploying code to env_a:.*OK$
    """

