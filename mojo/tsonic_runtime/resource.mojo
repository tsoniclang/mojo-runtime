def suppressed_error(error: Error, suppressed: Error) -> Error:
    return Error("SuppressedError: ", error, "; suppressed: ", suppressed)
