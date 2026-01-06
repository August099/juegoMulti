extends Node

@onready var addres = $UI/BoxContainer/VBoxContainer/LineEdit.text

func _on_host_pressed():
	$ServerManager.CreateServer()
	$UI.hide()

func _on_join_pressed():
	$ServerManager.CreateClient(addres)
