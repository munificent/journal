func ReadFile(filename string, param SomeType, block func(f *File)) {
    file := os.Open(filename)
    block(file) // Comment.
    file.Close()
}
