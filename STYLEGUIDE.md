#  Styleguide

This styleguide defines the conventions that have been agreed upon when writing Swift code at Boinx Software.
When contributing to this repository, the styleguide must be followed.

## Swift Code
In general, please refer to the [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide) for a set of sane *defaults*.
This document lists certain aspects of writing Swift code that either differ from the Ray Wenderlich Swift Style Guide or that are particularly important for our organization.

### Method and Conditional Braces
In contrast to many resources, we prefer method braces and other braces (if/else/switch/while etc.) to always **open on the line below** the statement and also close on a new line.

Preferred:

```swift
if someCondition
{
    // bla
}
else
{
    // foo
}

func myMethod(withArgument argument: Int, anotherArgument: Bool)
{
    // content
}
```
