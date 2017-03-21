_         = require 'lodash'
Sequelize = require 'sequelize'
Promise   = require 'bluebird'
config    = require(__dirname + '/../server/config/config.json').test
inflection = require 'inflection'
mocha = require 'mocha'
debug = require('debug') 'test'

return

orm = new Sequelize config.db.database, config.db.username, config.db.password, config.db

cache = {}

describe 'orm', ->
  before ->
    person = orm.define 'person',
      title: orm.Sequelize.STRING
      # extra: orm.Sequelize.STRING
      # attrr: orm.Sequelize.STRING
    , timestamps: false

    husband= orm.define 'husband',title: orm.Sequelize.STRING
    mother = orm.define 'mother', title: orm.Sequelize.STRING
    child  = orm.define 'child',  title: orm.Sequelize.STRING
    friend = orm.define 'friend', title: orm.Sequelize.STRING
    other  = orm.define 'other',  title: orm.Sequelize.STRING

    # o2o person have special person as husband of wife

    person.belongsTo person, as: 'husband'
    person.hasOne person, as: 'wife', foreignKey: 'husband_id'

    # o2m person have many persons as children of mother
    # m2o person have common person as mother of children

    person.belongsTo person, as: 'mother'
    person.hasMany person, as: 'children', foreignKey: 'mother_id'

    # m2m persons have many persons as pals of drugs

    person.belongsToMany person, through: 'friendship', as: 'pals', foreignKey: 'drug_id'
    person.belongsToMany person, through: 'friendship', as: 'drugs', foreignKey: 'pal_id'

    # person.addScope 'defaultScope', {include: all: true}, override: true

    orm.sync force: true
    .then ->
      person.create title: 'liana'
      .then (liana) ->
        cache.liana = liana
        Promise.all [
          liana.createMother title: 'anna'
          liana.createChild title: 'john'
          liana.createChild title: 'tom'
          liana.createHusband title: 'josef'
          liana.createPal title: 'kira'
          liana.createPal title: 'ola'
          liana.createDrug title: 'fi'
          liana.createDrug title: 'toma'
        ]

  describe 'associations', ->
    it 'should get associations', ->
      person = orm.models.person
      debug person.associations
      debug ( key for key of cache.liana when key.match /get/ )

      person.addHook 'beforeFind', 'alternative_m2m', (opt) ->
        return if !opt.includeExtra
        opt.include = _.compact opt.includeExtra.map (rel) =>
          if !(assoc = @.associations[rel.name])
            # debug "unrecognized association #{rel.name} of #{@.tableName}"
            return false
          return false if ~['BelongsToMany', 'HasMany'].indexOf assoc.associationType
          _.assign {}, rel.options, model: assoc.target, as: rel.name

      person.addHook 'afterFind', 'alternative_m2m', (list, opt) ->
        list = [list] if !_.isArray list
        return if !opt.includeExtra
        includes = _.filter opt.includeExtra, (rel) =>
          (assoc = @.associations[rel.name]) && ~['BelongsToMany', 'HasMany'].indexOf assoc.associationType
        ids = list.map (item) -> item.getDataValue 'id'
        # debug 'sas', ids
        Promise.each includes, (rel) =>
          assoc = @.associations[rel.name]
          (where = {})[assoc.foreignKey] = $in: ids
          if assoc.associationType == 'HasMany'
            (rel.options.attributes ?= []).splice 0, 0, assoc.foreignKey, 'id'
            return assoc.target.findAll _.assign {}, rel.options, where: where
            .then (links) -> links.forEach (link) -> list.forEach (item) ->
              item.setDataValue assoc.as, [] if !_.isArray item.getDataValue assoc.as
              return false if link[assoc.foreignKey] != item.id
              (item.getDataValue assoc.as).push link.get(plain: true)
          else if assoc.associationType == 'BelongsToMany'
            # assoc.target.findAll _.assign {}, rel.options, where: where

            return assoc.target.findAll( include:
              model: assoc.source
              as: inflection.pluralize(assoc.foreignKey.split('_')[0])
              through: attributes: []
              attributes: ['id']
              where: id: $in: ids
            ).then (links) ->
              debug '--', assoc.through, assoc.foreignKey, rel.name, JSON.stringify links.map (item) -> item.get plain: true

        # list = [list] if !_.isArray list
        # ids = (item.id for item in list)
        # Promise.each opt.includeExtra, (rel) =>
        #   assoc = @.associations[rel.as]
        #   (where = {})[assoc.foreignKey] = $in: ids
        #   query = """
        #     SELECT #{assoc.target.tableName}.*, #{assoc.through.model.tableName}.#{assoc.foreignKey} as ___key
        #     FROM #{assoc.through.model.tableName} LEFT JOIN #{assoc.target.tableName}
        #     ON (#{assoc.through.model.tableName}.#{inflection.singularize rel.as}_id = #{assoc.target.tableName}.id)
        #     WHERE #{assoc.through.model.tableName}.#{assoc.foreignKey} IN(:ids)
        #   """
        #   debug 'query', query
        #   orm.query query, replacements: {ids: ids}, type: orm.QueryTypes.SELECT
        #   .then (results, metadata) ->
        #     for item in list
        #
        #       item.setDataValue rel.as, (_.filter results, ___key: item.id).map (res) -> _.pick res, rel.attributes


      options = attributes: ['id', 'title'], includeExtra: [
        {name: 'notExisted'}
        {name: 'broken',   options: attributes: ['title']}
        {name: 'husband',  options: attributes: ['title']}
        {name: 'wife',     options: attributes: ['title']}
        {name: 'mother',   options: attributes: ['title']}
        {name: 'children', options: attributes: ['title']}
        {name: 'pals',     options: attributes: ['title'], through: attributes: []}
        {name: 'drugs',    options: attributes: ['title'], through: attributes: []}
      ]

      orm.models.person.findById 1, options
      .then (item) -> debug 'itemById', item.get(plain: true)

      # orm.models.person.findOne _.assign {}, options
      # .then (item) -> debug 'itemOne', item.get(plain: true)
      #
      # orm.models.person.findAll _.assign {}, options
      # .then (list) -> debug 'itemAll', list.map (item) -> item.get(plain: true)


      # orm.models.person.findAll where: {id: $in: [1, 3, 4, 7]}, attributes: ['title'], include: [
      #   {attributes: ['title'], model: person, as: 'husband'}
      #   {attributes: ['title'], model: person, as: 'wife'}
      #   {attributes: ['title'], model: person, as: 'mother'}
      #   {attributes: ['title'], model: person, as: 'children'}
      #   {attributes: ['title'], model: person, as: 'pals', through: attributes: []}
      #   {attributes: ['title'], model: person, as: 'drugs', through: attributes: []}
      # ]
      # .then (list) -> debug 'list', list.map (item) -> item.get plain: true

  #describe 'types of m2m'

  #describe 'show/edit filters'
