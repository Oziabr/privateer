module.exports = [
  #   'get  /:id one:show': (req, res) -> res.render "#{res.locals.route}/show", item: req.item
  # , 'post /:id/restore one:show': (req, res) -> req.item.restore().then (item) -> res.redirect "/#{res.locals.route}/#{item.id}"
]
