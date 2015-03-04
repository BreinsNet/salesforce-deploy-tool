@misc
Feature: Misc features related to sf

  In order to use sf
  As a user using 
  I want to be able to run sf misc functionality

  Scenario: I should be able to see the version of sf
    When I run `sf -v` interactively
    Then the exit status should be 0
    And the output should match /sf \d+\.\d+.\d+/
