---
  title: "GitHub Primer for Sinai Data Portal RA Work"
  author: "William L. Potter"
  date: 2022-06-01
  version: 1.0
---

This guide provides a brief overview of the GitHub features and practices we will employ for the Sinai Data Portal work undertaken by the Research Associates. The following reference sections may be of most interest:

- [Issue features](#issue-features)
- [Workflow for the `RA Portal work` Project](#workflow-for-the-ra-portal-work-project)
- [Procedures](#procedures)

## What is GitHub?

While GitHub is primarily used by software developers, its online file storage, remote collaboration, and version control features prove useful for a variety of projects. Many Digital Humanities researchers and Academic Libraries host their projects on GitHub. We have a GitHub repository for the Sinai projects for three main reasons:

1. Public, online storage: we store copies of a lot of our metadata on the GitHub repository
2. Version control: GitHub allows contributors to track changes made to the data in a repository, create branched versions for testing new features, and merge those branches into the main code base when they are ready for release. The version control features also enable remote collaboration, as GitHub will compare my changes with another person's changes and allow you to resolve any conflicts that may arise from multiple people working on the same files.
3. Issue tracking and project management: Of most direct relevance to the Research Associates, these features are the subject of the following sections.

For the RA data gathering work in particular, GitHub will provide us with a centralized place to discuss manuscript data, ask questions, provide feedback, and track progress.

## Issue Tracking with GitHub

The primary place we will communicate is through GitHub [issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues). Each manuscript will have its own issue (e.g., [Sinai Syriac 255](https://github.com/UCLALibrary/sinai_metadata/issues/18)) where we can discuss anything that may arise in gathering data on that manuscript. Each issue has a unique number which serves as its identifier (e.g., issue [#18](https://github.com/UCLALibrary/sinai_metadata/issues/18).

## Issue features

The following features of GitHub issues may prove useful to know about. (Full documentation may be found [here](https://docs.github.com/en/issues))

### Issue status

Issues can be either "open", meaning they are in progress or not fully resolved, or "closed", meaning work on them has been completed. Once closed, issues may be reopened if further work proves necessary. Even after issues are closed, the discussions associated with them remain as an archive of previous editorial decisions to which we can refer if needed.

### Comments on issues

Issues can be commented on with 'plain text'. However, GitHub does provide support for [markdown](https://daringfireball.net/projects/markdown/) which allows you to add ordered and unordered lists, links, code snippets, etc. You can also add these using the buttons provided in the comment interface. Switching between "Write" and "Preview" will show you how the comment will look once it's posted.

#### `@` Mentions in comments

The most important feature in issue comments is the ability to tag other users. Mentioning/tagging a user will also send them an email notification (if they have email notifications set up for their account). To mention a user, type `@` followed by their username. Example: `@wlpotter`. GitHub will begin auto-suggesting users after you type the `@` symbol.

#### Referencing other issues in Comments

As noted above, each issue has a distinct numerical identifier. This number allows you to reference other issues within an issue comment. For example, `#18` creates a link to [issue 18](https://github.com/UCLALibrary/sinai_metadata/issues/18). As with `@` mentions, GitHub will auto-suggest issues once you type the `#` character.

### Assignees

In addition to mentioning people in issue comments, you can also 'assign' a user to an issue. For instance, if you want someone to review your work on a particular manuscript, you can assign them to the corresponding issue. You will also be assigned to the issue for manuscripts you are working on.

### Labels

Labels help categorize and group related issues. The following are the primary labels you will encounter:

  - labels for manuscript type/phase: `1. Simple and composite manuscripts`, `2. Palimpsests`, and `3. Fragments and disjecta membra` all indicate the project phase into which this manuscript falls
  - `help wanted`: this label indicates that a question needs to be answered or problem needs to be resolved. Indicate the nature of the problem in the comments and assign either Dawn or Will to review.

### Milestones

Milestones provide another means of grouping issue. Unlike labels, an issue can be assigned to only one milestone. We use milestones to group phases of work, e.g. `Batch 1`. Milestones will be assigned as issues are created, so it is unlikely that you will need to edit these. However, these may prove useful for filtering purposes (on which see [Filtering and sorting issues](#filtering-and-sorting-issues), below).

### Projects

Assigning an issue to a project allows us to make use of GitHub's project tracking features. All issues related to the RA work for gathering data for the Sinai Data Portal will be assigned to the [same project](https://github.com/UCLALibrary/sinai_metadata/projects/1). Projects will be explained in more detail [below](#github-projects).

## Filtering and sorting issues

To see all open issues, go to: https://github.com/UCLALibrary/sinai_metadata/issues. Here you can filter and sort by label, assignee, projects, and milestones. You can also search for specific keywords in the search bar. (Note that while these filters are also available in GitHub Project view, the functionality is still in development and remains somewhat difficult to use).

## GitHub projects

For issues related to the RA work of gathering manuscript data for inclusion in the SDP, we have created a [GitHub Project](https://docs.github.com/en/issues/trying-out-the-new-projects-experience/about-projects), called [Portal RA work](https://github.com/UCLALibrary/sinai_metadata/projects/1). GitHub Projects are a [kanban-style board](https://en.wikipedia.org/wiki/Kanban), with various columns corresponding to various points in a development workflow.

## Workflow for the `RA Portal work` Project

The issues assigned to [this project](https://github.com/UCLALibrary/sinai_metadata/projects/1) will follow this workflow:

### To do

Newly created issues will appear in this column. If you are assigned to an issue in this column, it means that you may begin working on this manuscript whenever you are ready. Once you begin working on that manuscript, move the card into the `In progress` column.

Issue cards may also appear here after the data has been reviewed (see [Review in progress](#review-in-progress), below). If, after undergoing review, there are requested revisions or more data needed, Dawn and/or Will will move the issue card back to the `To do` column. Once you begin working on the requested revisions, you can move the issue into the `In progress` column again.

### In progress

Issues in this column represent manuscripts for which you are actively gathering data. If questions or problems arise, you can ask them using the issue's comments.

Once data has been sufficiently gathered and you are ready for Dawn and/or Will to review, move the card to the `Review in progress` column. Make sure to also assign the issue to Will and Dawn and share the collected data with them.

### Review in progress

Issues in this column will be reviewed by Dawn and/or Will. If the gathered data is sufficient and no problems are discovered, they will move it into the `Reviewer approved` column.

If there are any requested revisions to the data, or if more information is needed, they will move this card back to the `To do` column. They will reassign the original RA and notify them of the requested changes. The card can then proceed through the `To do` and `In progress` columns again.

### Reviewer approved

Cards in this column have undergone a successful initial review. If any additional data processing steps are needed, they may remain in this column. Once all tasks associated with a given manuscript issue are complete, the card can be moved to the `Done` column (note that this will occur automatically once the issue is 'closed').

### Done

This column will contain issues that have been resolved.

## Procedures

The following is a non-exhaustive lists of procedures to follow for using GitHub for Data Portal RA work. These procedures are scenario-based and will be expanded as new scenarios arise that are not covered under this list. If you come across a scenario not covered, please send an email to Will Potter asking how to proceed.

### I have a question about an aspect of my work on a given manuscript

1. Post the question as a comment on the issue for that manuscript
2. Tag and/or assign Will (@wlpoter) and/or Dawn (@kirschbombe) to the issue
3. Add the `help wanted` label to the issue
- add the `help wanted` label to the issue

These steps will alert Will and Dawn to respond to the question, and discussion can take place in the issue comments. If needed, we can schedule a time to discuss the problem(s) via Zoom.

### I have completed data gathering for a manuscript and am ready for it to be reviewed

1. In the [project](https://github.com/UCLALibrary/sinai_metadata/projects/1), move the ms issue to the `Review in progress` column
2. Assign Will (@wlpoter) and Dawn (@kirschbombe) to the issue
  - Optionally leave a comment tagging them and let them know it is ready for review
3. Share the gathered data with Will and Dawn
   - Either send the document with the data via email or attach/link to the document in the manuscript's issue

### All my assigned manuscripts are either completed or under review, and I am ready for another

1. Send Will an email either requesting a specific manuscript or asking that one be assigned from the pool of candidates
2. Will will create an issue for that ms, assign you to that issue, and add the requisite labels, etc.
