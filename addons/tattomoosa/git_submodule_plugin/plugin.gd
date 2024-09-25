@tool
extends EditorPlugin

const GitSubmodulePlugin := preload("./src/git_submodule_plugin.gd")
const GitSubmoduleSettingsTree := preload("./src/editor/git_submodule_project_settings/git_submodule_settings.tscn")
const GitSubmoduleFileDockPugin := preload(
    "./src/editor/file_dock_plugin/git_submodule_file_dock_plugin.gd"
)

var submodule_settings := GitSubmoduleSettingsTree.instantiate()
var file_system_dock_plugin := GitSubmoduleFileDockPugin.new()

func _enter_tree() -> void:
  _add_file_dock_plugin()
  add_control_to_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, submodule_settings)

func _exit_tree() -> void:
  _remove_file_dock_plugin()
  remove_control_from_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, submodule_settings)

func _add_file_dock_plugin() -> void:
  file_system_dock_plugin = GitSubmoduleFileDockPugin.new()
  file_system_dock_plugin.initialize()
  file_system_dock_plugin.patch_dock()

func _remove_file_dock_plugin() -> void:
  # file_system_dock_plugin.file_system_dock = get_editor_interface().get_file_system_dock()
  file_system_dock_plugin.queue_free()