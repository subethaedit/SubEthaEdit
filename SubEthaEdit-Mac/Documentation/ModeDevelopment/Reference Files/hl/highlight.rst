Test Content
------------

.. code-block:: c++
    // This is C++ code
    class Foo { int bar; };

.. code-block:: python
    # This is Python code
    class Foo(object):
        def __init__(self):
            pass

.. code-block:: c++
  int foo = 5; // 'foo' should not have the attribute of the above line

Here is a |TLA|. Does it highlight if it is only |TLA|-like? It should...

.. |TLA| replace:: Three Letter Acronym

:This: ...is a field.
:An *exciting* field: Isn't it, though?
:A ``literal`` like this: ...is often used in e.g. CMake documentation.

:This:
  ...is also a field.

:``This``: ...*should* be a field, but isn't; HL needs a look-behind assert

::
  I hope I am code, and not a field!

:role:`text` is not a field.
Nor is :role:`text`. But `text`:role: should also be a role.

This text [here] should not be special, but [this]_ is a footnote.
This [isn't]_ a footnote; no special characters allowed!

Full Stop_. That should make 'stop' a single-word link.

* Let's try some indented stuff...
  ::
    I should be code!

  And I should *not* be code!

  .. note:: This should be a directive, not be a comment.

  The definition of `this example`_ link (below) should also not be a comment:

  .. _this example: http://www.example.com

* Still a list.

A literal ``example``::
  Working?

This *is* a .. code-block::
  ...but ".. code-block" is normal text.

.. This is a comment, which should highlight things like ALERT.
   This is still the comment.

This is not the comment.
