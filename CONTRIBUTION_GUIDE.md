# Contributing to toolshed

We are happy you want to contribute to the toolshed codebase.Your ideas and help are very much welcome.

## Getting Started

This describes how to contribute to toolshed:  the tools we use to track and
coordinate the work that is happening and that needs to happen. This also describes the
*workflow* -- the processes and sequences for getting contributions merged into the project in an organized and coherent way.

We keep our code on [GitHub](http://github.com) and use [git](https://git-scm.com) for version control.

First ensure set up your development environment following these steps:

1. installing elixir  [install elixir](https://elixir-lang.org/install.html).

## General Steps
To get involved please follow these steps:

#### 1. Get the system working on your development environment by running:
  
  1. `mix deps.get` to install depedencies

  2. `mix test`  this should be green to ensure everything is working properly

#### 2. Cloning the application
Fork the application from [toolshed](https://github.com/fhunleth/toolshed).Then clone  your forked repository.

#### 3. Look at what needs to be done on:

 * [New issues](https://github.com/fhunleth/toolshed/issues) column - feel free to start work

*  review [open PRs](https://github.com/fhunleth/toolshed/pulls) on GitHub - leave comments or collaborate if interested.


##  GitHub and git

Our **default working branch is `main`**.  We do work by creating branches off `main` for new features and bugfixes.

Any *feature* should include appropriate  tests.

A *bugfix* may include a unit test depending on where the bug occurred, but fixing a bug should start with the creation of a test that replicates the bug, so that any bugfix submission will include an appropriate test as well as the fix itself.

You should  work with a fork that is:

clone from your forked repository like so:

 ```git clone https://github.com/your_username/toolshed.git```  

or
```git clone git@github.com:your_username/toolshed.git``

Ensure you have two remotes that is `upstream` for the main repo  and  `origin`for your forked repo(you can name the way you wish) like so:


```bash
git remote add upstream git@github.com:fhunleth/toolshed.git
```
 or
```bash
git remote add upstream https://github.com/fhunleth/toolshed.git
```
You can check that you have the two remotes like so:
```bash
git remote -v
```


 Before starting work on a new feature or bugfix, please ensure you have [synced your fork to upstream/develop](https://help.github.com/articles/syncing-a-fork/):

```
git pull upstream main
```

Note that you should be re-syncing as frequently as possible on your
feature/bugfix branch to ensure that you are always building on top of very latest main code.

### Pull Requests, committing and branch naming


When creating a branch, ensure it has an issue number, this number should the issue id assigned to the issue you are working on

```
git checkout -b 58-add-contributing_md
```

Please ensure that each commit in your pull request makes a single coherent change and that the overall pull request only includes commits related to the specific GitHub issue that the pull request is addressing.  This helps the project managers understand the PRs and merge them more quickly.

```
This add contribution.md to the project
fixes #58
```

Your PR can either be a draft or Ready for review.


Pull Request Review
-------------------

Currently [Frank](https://github.com/fhunleth) is project managing toolshed.  He will review your pull request as soon as possible

The project manager will review the pull request for coherence with the specified feature or bug fix, and give feedback on code quality, user experience, documentation and git style.  Please respond to comments from the project managers with explanation, or further commits to your pull request in order to get merged in as quickly as possible.


If your tests are passing locally, but failing on CI, please have a look at the fails and if you can't fix, please do reach out to the project manager.
