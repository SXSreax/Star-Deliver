extends Resource
class_name Item

@export var icon : Texture2D
@export var name : String

@export_enum("Weapon", "Consumable", "Armour", "Package")
var type = "Weapon"

@export_multiline var description: String
