DESCRIPTION OF PULL REQUEST
    
Overview
========

Description
-----------


List of changes
---------------

- 
- 
- 

Links to relevant issues
------------------------

- 
- 
- 

Links to related pull requests
------------------------------

- 
- 
- 

Links to relevant documentation (Notion, external)
--------------------------------------------------

- 
- 
- 

Example screenshots, [gifs, or videos](https://www.getcloudapp.com/)
--------------------------------------------------------------------

- 

How thoroughly should the code be reviewed and tested? Why?
-----------------------------------------------------------



What code can others reuse?
---------------------------

- 

What are general test steps or cases?
-------------------------------------

1. 

What edge cases should be considered?
-------------------------------------

- 


Pull Request Expectations
-------------------------

See the Working Agreements in the Notion project page for additional considerations.

Guidelines
==========

- The Reviewer is encouraged to ask questions and share suggestions.
- The Reviewer must make it clear what comments are not mandatory.
- The Reviewer must let the Submitter know if modifying the branch.
- The Submitter is encouraged to backlog any larger changes.
- The Submitter makes the final call on any issue not consider a bug.
- The Submitter should merge in the code unless otherwise discussed.

Submitter checklist
===================

Branching, Rebasing, and Merging

- Branch off of `develop` typically.
- Only branch from a feature branch if it is unlikely to change before merge.
- Prefix branches with `feature/` or `bugfix/`.
- Rebase early and often. Use Merge if there are too many risky conflicts.

Before assigning reviewers

- [ ] Review your own code before assigning to others.
- [ ] Rebase or merge from develop branch.
- [ ] Do a smoke test after all merges
- [ ] Review the QA section on the Project page for regression test cases.
- [ ] Look for any TODOs, dead code, or unnecessary log statements.

Information Sharing

- [ ] Announce any important changes in Slack
- [ ] Update the project board task status and fill in any extra information.
- [ ] Update the project board with any issues or future improvements.
- [ ] Update the README.md
- [ ] Update Notion project page
- [ ] Update Notion technology pages

Reviewer checklist
==================

As a reviewer, it is suggested that anything is fair game to comment, but style or
implementation approach should be respected and at the discretion of the submitter,
unless it substantially affects the architecture of the codebase. 

- [ ] Make it clear whether each comment is a bug, a suggestion, or just an FYI.
- [ ] Look for any TODOs, dead code, or unnecessary log statements.
- [ ] Brainstorm any additional test cases.
- [ ] Pull down and test the code in all but the most simple pull requests.


💔Thank you!