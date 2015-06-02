@config
Feature: Configure the user credentials interactively

  In order to use sf
  As a user using 
  I want to be able to configure my credentials interactively

  Scenario: Running sf config it has to interactively setup my environment
    When I run `sf config` interactively
    And I type "john.doe@example.com"
    And I type "SecurePassword"
    And I type "John Doe"
    And I type "john.doe@example.com"
    And I type "testEnv"
    Then the exit status should be 0
    And the file "~/.sf/credentials.yaml" should match /username.*john.doe@example.com/
    And the file "~/.sf/credentials.yaml" should match /password.*SecurePassword/
    And the file "~/.sf/salesforce.sbox" should match /.+/
