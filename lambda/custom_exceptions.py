# Custom Exceptions
class InvalidHeaderError(ValueError):
    """Raised when the type header is invalid."""


class InvalidInputError(Exception):
    pass


class InvalidPathError(Exception):
    pass
