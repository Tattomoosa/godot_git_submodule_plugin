@tool
extends PopupPanel

signal added

enum Origin {
	GITHUB,
	NUL_SEP,
	CUSTOM
}
const GitSubmodulePlugin := preload("../../git_submodule_plugin.gd")
const GitSubmoduleAccess := GitSubmodulePlugin.GitSubmoduleAccess
const StatusOutput := preload("../common_controls/git_submodule_output.gd")

var origin_urls := {
	Origin.GITHUB: "git@github.com:%s.git",
	Origin.CUSTOM: "%s"
}

@onready var repo_edit : LineEdit = %RepoEdit
@onready var branch_edit : LineEdit = %BranchEdit
@onready var commit_edit : LineEdit = %CommitEdit
@onready var origin_menu : OptionButton = %OriginMenu
@onready var custom_origin_edit : LineEdit = %CustomOriginEdit
@onready var output : StatusOutput = %StatusOutput

@warning_ignore("return_value_discarded")
func _ready() -> void:
	output.loading = false
	visibility_changed.connect(reset)
	repo_edit.text_changed.connect(_on_edit_changed.unbind(1))
	branch_edit.text_changed.connect(_on_edit_changed.unbind(1))
	commit_edit.text_changed.connect(_on_edit_changed.unbind(1))
	_on_edit_changed()

func _on_edit_changed() -> void:
	var color := get_theme_color("font_disabled_color", "Editor")
	var color_tag := "[color=#%s]" % color.to_html()

	var repo_text := repo_edit.text
	if repo_text == "":
		repo_text = color_tag + "%s[/color]" % "{author}/{repo}"

	var branch_text := branch_edit.text
	if branch_text != "":
		branch_text = "-b [/color]%s%s " % [branch_text, color_tag]

	var commit_text := commit_edit.text


	output.clear()
	output.print(color_tag,
			"git clone ",
			branch_text,
			(get_origin_string() % ("[/color]" + repo_text + color_tag)),
			"[/color] ",
			commit_text)

func reset() -> void:
	repo_edit.clear()
	branch_edit.clear()
	commit_edit.clear()
	custom_origin_edit.clear()
	output.clear()
	_on_edit_changed()

func add_repo() -> void:
	output.loading = true
	var repo := repo_edit.text
	var branch := branch_edit.text
	var commit := commit_edit.text
	var origin_string := get_origin_string()
	var upstream_url := (origin_string % repo)\
		if "%s" in origin_string\
		else origin_string
	output.append_text(
		"Cloning from %s into %s..." % [
			upstream_url,
			GitSubmodulePlugin.submodules_root.path_join(repo)
	])
	await get_tree().process_frame
	await get_tree().process_frame
	var out : Array[String] = []
	print("does upstream exist here?", upstream_url)
	var err := GitSubmoduleAccess.clone(
		repo,
		upstream_url,
		branch,
		commit
	)
	if err != OK:
		push_error("Error cloning %s " % repo, " ",error_string(err))
	output.loading = false
	if err != OK:
		output.print(
			"[color=red]",
			"Error encountered during git clone: %s\n" % error_string(err),
			"Git Output:\n",
			"\n".join(out),
			"[/color]",
		)
		return
	output.print("OK")
	await get_tree().process_frame
	added.emit()
	hide()

func get_origin_string() -> String:
	var index := origin_menu.selected
	if index == Origin.CUSTOM:
		return custom_origin_edit.text
	return origin_urls[index]

func update_origin(origin: int) -> void:
	print("update origin: ", origin)
	if origin == Origin.CUSTOM:
		custom_origin_edit.editable = true
		custom_origin_edit.text = ""
		return
	custom_origin_edit.editable = false
	match origin:
		Origin.GITHUB:
			custom_origin_edit.text = "git@github.com:%s.git"