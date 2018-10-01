
# Contributing Guidelines

#### General Feedback

Create a new issue on our [Issues page](https://github.com/LoneMonkeyProductions/SubEthaCode/issues). Issues and discussions are expected to be written in english.

Bug reports __should__ include your environment. You can generate a bug report template automatically in SubEtha Code by selecting "Help" > "Create Bug Report…" in the menu.

## Contributing Code

### Repository Structure

The main development Workflow for SubEtha Code is based on [git-flow](https://nvie.com/posts/a-successful-git-branching-model/). The main development happens on the `develop` branch. In addition to the `feature` branches for longer term contributions, contributers are expected to create pull requests based on `issue` named branches. Each pull request **must have** a github issue attached. Both feature and issue branches need to be of the form `feature/<issue#>[-description]`.

E.g. `feature/312-ProjectInterface` or `issue/333-DarkMode` 


### Pull Requests

* Fork the project
* Base your changes on the most recent state of `develop` on a `issue/<issue#>[-description]` or `feature/<issue#>[-description]` branch
* Submit your pull request

### General Code Guidelines

* The main **SubEtha Code** repository will not take Swift-Code. If you want to go down that road feel free to fork the project.
* New Objective-C code has to be ARC. Plain C and C++ code is generally welcome if it has a purpose (Performance, or alignment with a dependent code base)
* Nullability annotations generally are discouraged. If you contribute a tight subset of code that would benefit greatly in correctness, argue your case.
* Addition of dependencies is discouraged, it should be as self contained as possible. The project will not integrate usage of package managers.


### Coding Style Guide

**SubEtha Edit** is a rather old codebase. As such in contains some antiquated code style in existing code. Here is a shortlist of how new could should look like.

* Be sparse with comments, if code is unclear look for more self expressing ways. Longer blocks of explanations of concepts is acceptable if needed.
* Basic style (open braces on same line, space after if/while/etc, argument names natural):
 
```objectivec
- (void)announceAndBecomeVisibleAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[self setIsAnnounced:YES];
	}
}
```

* Use auto-synthesized properties for new code
* Early exits are discouraged. Use a variable for the return value and return at the end for easy debuggability. Generally optimize for both the code reading programmer and Person debugging.


# Code Of Conduct

# Contributor Covenant Code of Conduct

## Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, sex characteristics, gender identity and expression,
level of experience, education, socio-economic status, nationality, personal
appearance, race, religion, or sexual identity and orientation.

## Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
  advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

## Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team at **subetha-code at lone.monkey.productions**. All complaints will be reviewed and investigated and will result in a response that
is deemed necessary and appropriate to the circumstances. The project team is
obligated to maintain confidentiality with regard to the reporter of an incident.
Further details of specific enforcement policies may be posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4,
available at https://www.contributor-covenant.org/version/1/4/code-of-conduct.html

[homepage]: https://www.contributor-covenant.org
