   # "list" command range which may refer to locations
    def p_list_range(self, args):
        '''
        range_start  ::= opt_space range
        range ::= location
        range ::= location opt_space COMMA opt_space NUMBER
        range ::= location opt_space COMMA opt_space OFFSET
        range ::= COMMA opt_space location
        range ::= location opt_space COMMA
        range ::= location
        range ::= DIRECTION
        '''

    # location that is used in breakpoints, list commands, and disassembly
    def p_location(self, args):
        '''
        opt_space   ::= SPACE?
        location_if ::= location
        location_if ::= location SPACE IF tokens
        # Note no space is allowed between FILENAME and NUMBER
        location    ::= FILENAME COLON NUMBER
        location    ::= FUNCNAME
        # If just a number is given, the the filename is implied
        location    ::= NUMBER
        location    ::= METHOD
        location    ::= OFFSET
        # For tokens we accept anything. Were really just
        # going to use the underlying string from the part
        # after "if".  So below we all of the possible tokens
        tokens      ::= token+
        token       ::= COLON
        token       ::= COMMA
        token       ::= DIRECTION
        token       ::= FILENAME
        token       ::= FUNCNAME
        token       ::= NUMBER
        token       ::= OFFSET
        token       ::= SPACE
