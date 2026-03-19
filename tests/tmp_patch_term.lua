print('before', type(term.redirect))
term.redirect = function() return true end
print('after', type(term.redirect))
term.redirect(term.current())
print('ok redirect call')
