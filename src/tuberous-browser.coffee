potato = require 'potato'
async = require 'async'


MongoID = potato.String
    type: 'string'

Date = potato.Literal
    default: -> new Date()

ForeignObject = (ForeignType)-> potato.String

Model = potato.Model
    
    components:
        _id: MongoID


module.exports =
    Model: Model
    Date: Date
    MongoID: MongoID