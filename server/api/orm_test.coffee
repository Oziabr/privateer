_         = require 'lodash'
fs        = require 'fs'
path      = require 'path'

Sequelize = require 'sequelize'
basename  = path.basename module.filename
env       = process.env.NODE_ENV || 'development'
config    = require(__dirname + '/../config/config.json')[env]

orm = new Sequelize config.db.database, config.db.username, config.db.password, config.db

person = orm.define 'person', title: orm.Sequelize.STRING

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


# ---------

# o2o wife has special dear
mother.belongsTo husband, as: 'dear'
husband.hasOne mother, as: 'wife', foreignKey: 'dear_id'

# o2m mother have many children
# m2o children have common mother
child.belongsTo mother, as: 'mom'
mother.hasMany child, as: 'babies', foreignKey: 'mom_id'

# m2m others have many friends
other.belongsToMany friend, through: 'frship', as: 'pals', foreignKey: 'drug_id'
friend.belongsToMany other, through: 'frship', as: 'drugs', foreignKey: 'pal_id'

orm.sync force: true
.then ->
  console.log 'synched'
  mother.create title: 'mom'
  .then (mom) ->
    console.log 'mother-child', !!mom.getBabies, !!mom.setBabies, !!mom.addBabies,
      !!mom.addBaby, !!mom.createBaby, !!mom.removeBabies, !!mom.removeBaby,
      !!mom.hasBabies, !!mom.hasBaby, !!mom.countBabies
    console.log 'mother-husband', !!mom.getDear, !!mom.setDear, !!mom.createDear

  husband.create title: 'tom'
  .then (tom) ->
    console.log 'husband-mother', !!tom.getWife, !!tom.setWife, !!tom.createWife

  child.create title: 'john'
  .then (john) ->
    console.log 'child-mother', !!john.getMom, !!john.setMom, !!john.createMom

  friend.create title: 'gleb'
  .then (gleb) ->
    console.log 'friend-other', !!gleb.addDrug, !!gleb.setDrugs

  other.create title: 'kot'
  .then (kot) ->
    console.log 'other-friend', !!kot.addPal, !!kot.setPals

  person.create title: 'liana'
  .then (liana) ->
    liana.createMother title: 'anna'

    liana.createChild title: 'john'
    liana.createChild title: 'tom'
    liana.createHusband title: 'josef'

    liana.createPal title: 'kira'
    liana.createPal title: 'ola'
    liana.createDrug title: 'fi'
    liana.createDrug title: 'toma'
