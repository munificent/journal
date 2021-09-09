numWeasels > numCakes ifTrue: [
    'Not enough cakes!' print
] ifFalse: [
    i := 0.
    [ i < numWeasels ] whileTrue: [
        'A weasel eats a cake!' print.
        i := i + 1
    ]
]
