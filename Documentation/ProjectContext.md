# Project Context

This document outlines the desired behaviour of the "Project Context" feature.

## Rationale

Currently SubEthaEdit operates on a per file basis and thus does not provide any features on a project level like:

- powerful project wide search and replace 
- constrain autocomplete for files in the same context
- simple access and recognition of build and linting scripts for the project opened
- project wide navigation (e.g. opening up of imported files, etc)
- SCM integration
- ...

Therefore a concept and an implementation of a Project Context is needed.

## Definition

- Workspace: The workspace is the root entity for all project related information like the project base path. Documents can belong to at most one workspace. 

## Behaviour

### Workspaces

Workspaces are created if:

- The see tool is used to open a folder `see ./myfolder`
- If a folder is opened via one of the system provided functionalities (dragged on SEE icon, opened via Fild > Open, ...)

If a folder within an already open workspace is opened, no new workspace will be created. Instead the workspace window of the existing workspace will be displayed and the folder will be highlighted

Workspaces are dismissed if:
- All documents of the workspace are closed AND
- All Workspace windows are closed


### Documents

Every document can belong to at least one workspace. If it does so, in the upper right corner of the document window, a little "Project" icon is displayed. Clicking on this icon will reveal the Workspace Window and select the corresponding file.

If a new file is created or opened and the path of the file is contained in a workspace, it will be assigned to that workspace. If there a multiple workspaces open, the topmost one will be used. For example if the path of the file is `/foo/bar/foo.txt` and a workspace exists with the base path `/foo` as well as one with the base path `/foo/bar` it will be assigned to the latter one.

### Workspace Window

The workspace displays the tree-like file structure of a workspace. Double-Clicking a file will open the corresponding document. There can only be one workspace window per workspace. 

### Collaboration

At the moment, workspaces have no effect on how collaboration works.

## Implementation
Workspaces are represented by an `SEEWorkspace` object and managed by the `SEEWorkspaceController`. The diagram shows the relations between the Document & Workspace related objects.

```
 +-----------------------------+        +-----------------------------+
 |                             |        |                             |
 | SEEWorkspaceController      |<----1--+ SEEDocumentController       |
 |                             |        |                             |
 +-------------+---------------+        +--------------+--------------+
               *                                       *
               |                                       |
               v                                       v
 +-----------------------------+        +-----------------------------+
 |                             |        |                             |
 | SEEWorkspace                +-*----->| NSDocument                  |
 |                             |        |                             |
 +-----------------------------+        +-----------------------------+
 ```


