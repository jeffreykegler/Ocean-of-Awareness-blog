def t_direction(self, s):
        r'^[+-]$'
        # Used in the "list" command
        self.add_token('DIRECTION', s)
        self.pos += len(s)

    # Recognize integers
    def t_number(self, s):
        r'\d+'
        pos = self.pos
        self.add_token('NUMBER', int(s))
        self.pos = pos + len(s)

    # Recognize list offsets (counts)
    def t_offset(self, s):
        r'[+]\d+'
        pos = self.pos
        self.add_token('OFFSET', s)
        self.pos = pos + len(s)

    # Recognize addresses (bytecode offsets)
    def t_address(self, s):
        r'[*]\d+'
        pos = self.pos
        self.add_token('ADDRESS', s)
self.pos = pos + len(s)
