@config
Feature: Configure the user credentials interactively

  In order to use sf
  As a user using 
  I want to be able to configure my credentials interactively

  Scenario: Running sf config it has to interactively setup my environment
    When I run `sf config` interactively
    And I type my salesforce production_username
    And I type my salesforce production_password
    And I type my salesforce git_full_name
    And I type my salesforce git_email_address
    And I type my salesforce sandbox
    Then the exit status should be 0
    And the file "~/.sf/credentials.yaml" should contain "username"
    And the file "~/.sf/credentials.yaml" should contain "password"
    And the file "~/.sf/salesforce.sbox" should match /.+/
