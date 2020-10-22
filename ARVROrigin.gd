# To view log/print messages use `adb logcat -s godot:* GodotOVRMobile:*` from a command prompt
extends ARVROrigin

var ovr_init_config = null;
var ovr_performance = null;
var ovr_display_refresh_rate = null;
var ovr_guardian_system = null;
var ovr_tracking_transform = null;
var ovr_utilities = null;
var ovr_vr_api_proxy = null;
var ovr_input = null;


var controllers_vibration_duration = {}
var ovrVrApiTypes = load("res://addons/godot_ovrmobile/OvrVrApiTypes.gd").new();
var was_world_scale = 1.0

var fix_hand_position = false

func _ready():
	var ovr = _initialize_ovr_mobile_arvr_interface()
	if not ovr:
		var openvr = _initialize_openvr_arvr_interface()
		if not openvr:
			if OS.get_name()=="Android" or OS.get_name()=="iOS":
				var nm = _initialize_native_mobile_arvr_interface()
				fix_hand_position = true
			else:
				self.transform.origin.y = 1.85
				fix_hand_position = true



var _mouse_offset = Vector2()
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)

export (float, 0.0, 1.0) var sensitivity = 0.2
export var smoothness = 0.5
export (int, 0, 360) var yaw_limit = 360
export (int, 0, 360) var pitch_limit = 360



export var move_speed = 1.0

func _input(event):
	if event is InputEventMouseMotion:
		_mouse_offset = event.relative
		

func _process(delta_t):
	_check_and_perform_runtime_config()
	_check_move(delta_t)
	_check_worldscale()
	_update_controllers_vibration(delta_t)
	if fix_hand_position: 
		_process_mouse_rotation()
	else:
		_process_6dof_joystick_turns()
	_process_keys()
	
	
func _process_mouse_rotation():
	var offset = Vector2(Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left"),
							Input.get_action_strength("rotate_down") - Input.get_action_strength("rotate_up"));
	offset += _mouse_offset * sensitivity
	_mouse_offset = Vector2()
	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + offset.y * (1.0 - smoothness)
	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)
	_total_yaw += _yaw
	_total_pitch += _pitch
	
	$ARVRCamera.rotate_y(deg2rad(-_yaw))
	$ARVRCamera.rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))
	
	$LeftTouchController.rotation = $ARVRCamera.rotation
	$LeftTouchController.translation = Vector3(-0.2,-0.1,-0.2).rotated(Vector3.RIGHT, $LeftTouchController.rotation.x).rotated(Vector3.UP, $LeftTouchController.rotation.y)
	
	$RightTouchController.rotation = $ARVRCamera.rotation
	$RightTouchController.translation = Vector3(0.2,-0.1,-0.2).rotated(Vector3.RIGHT, $LeftTouchController.rotation.x).rotated(Vector3.UP, $LeftTouchController.rotation.y)
	
export var quick_turn_degrees=45
var _joy_centered=true

func _process_6dof_joystick_turns():
	var offset = Vector2(0,0)
	if $RightTouchController.get_is_active():
		var x = $RightTouchController.get_joystick_axis(0)
		if quick_turn_degrees==0:
			offset.x = x
		else:
			if _joy_centered:
				if x > 0.2:
					offset.x = quick_turn_degrees
					_joy_centered = false
				elif x < -0.2:
					offset.x = -quick_turn_degrees
					_joy_centered = false
			else:
				if x <= 0.2 and x >= -0.2:
					_joy_centered = true
	else:
		offset.x=Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left")
	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	_total_yaw += _yaw
	
	self.translate($ARVRCamera.translation)
	self.rotate_y(deg2rad(-_yaw))	
	self.translate(-$ARVRCamera.translation)
	

func _process_keys():
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("center_hmd"):
		ARVRServer.center_on_hmd(true, true)

func _initialize_native_mobile_arvr_interface():
	var arvr_interface = ARVRServer.find_interface("Native mobile")
	if arvr_interface and arvr_interface.initialize():
		get_viewport().arvr = true
		return true
	return false

func _initialize_openvr_arvr_interface():
	var arvr_interface = ARVRServer.find_interface("OpenVR")
	if !arvr_interface:
		print("Couldn't find OpenVR interface")
	else:
		if arvr_interface.initialize():
			get_viewport().arvr = true
			get_viewport().keep_3d_linear = true
			OS.vsync_enabled = false
			Engine.target_fps = 90	
			Engine.iterations_per_second = 90
			return true
		else:
			print("Couldn't initialize OpenVR")
	return false


func _initialize_ovr_mobile_arvr_interface():
	var arvr_interface = ARVRServer.find_interface("OVRMobile")
	if !arvr_interface:
		print("Couldn't find OVRMobile interface")
	else:
		ovr_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns");
		if (ovr_init_config):
			ovr_init_config = ovr_init_config.new()
			ovr_init_config.set_render_target_size_multiplier(1) # setting to 1 here is the default

		if arvr_interface.initialize():
			get_viewport().arvr = true
			Engine.iterations_per_second = 72 # Quest

			ovr_display_refresh_rate = load("res://addons/godot_ovrmobile/OvrDisplayRefreshRate.gdns");
			ovr_guardian_system = load("res://addons/godot_ovrmobile/OvrGuardianSystem.gdns");
			ovr_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns");
			ovr_tracking_transform = load("res://addons/godot_ovrmobile/OvrTrackingTransform.gdns");
			ovr_utilities = load("res://addons/godot_ovrmobile/OvrUtilities.gdns");
			ovr_vr_api_proxy = load("res://addons/godot_ovrmobile/OvrVrApiProxy.gdns");
			ovr_input = load("res://addons/godot_ovrmobile/OvrInput.gdns")


			if (ovr_display_refresh_rate): ovr_display_refresh_rate = ovr_display_refresh_rate.new()
			if (ovr_guardian_system): ovr_guardian_system = ovr_guardian_system.new()
			if (ovr_performance): ovr_performance = ovr_performance.new()
			if (ovr_tracking_transform): ovr_tracking_transform = ovr_tracking_transform.new()
			if (ovr_utilities): ovr_utilities = ovr_utilities.new()
			if (ovr_vr_api_proxy): ovr_vr_api_proxy = ovr_vr_api_proxy.new()
			if (ovr_input): ovr_input = ovr_input.new()

			_connect_to_signals()

			print("Loaded OVRMobile")
			return true
		else:
			print("Failed to enable OVRMobile")
			return false

func _connect_to_signals():
	if Engine.has_singleton("OVRMobile"):
		var singleton = Engine.get_singleton("OVRMobile")
		print("Connecting to OVRMobile signals")
		singleton.connect("HeadsetMounted", self, "_on_headset_mounted")
		singleton.connect("HeadsetUnmounted", self, "_on_headset_unmounted")
		singleton.connect("InputFocusGained", self, "_on_input_focus_gained")
		singleton.connect("InputFocusLost", self, "_on_input_focus_lost")
		singleton.connect("EnterVrMode", self, "_on_enter_vr_mode")
		singleton.connect("LeaveVrMode", self, "_on_leave_vr_mode")
	else:
		print("Unable to load OVRMobile singleton...")

func _on_headset_mounted():
	print("VR headset mounted")

func _on_headset_unmounted():
	print("VR headset unmounted")

func _on_input_focus_gained():
	print("Input focus gained")

func _on_input_focus_lost():
	print("Input focus lost")

func _on_enter_vr_mode():
	print("Entered Oculus VR mode")

func _on_leave_vr_mode():
	print("Left Oculus VR mode")

# many settings should only be applied once when running; this variable
# gets reset on application start or when it wakes up from sleep
var _performed_runtime_config = false

# here we can react on the android specific notifications
# reacting on NOTIFICATION_APP_RESUMED is necessary as the OVR context will get
# recreated when the Android device wakes up from sleep and then all settings wil
# need to be reapplied
func _notification(what):
	if (what == NOTIFICATION_APP_PAUSED):
		pass
	if (what == NOTIFICATION_APP_RESUMED):
		_performed_runtime_config = false # redo runtime config


func _check_and_perform_runtime_config():
	if _performed_runtime_config: return

	if (ovr_performance):
		#ovr_performance.set_clock_levels(1, 1)
		#ovr_performance.set_extra_latency_mode(ovrVrApiTypes.OvrExtraLatencyMode.VRAPI_EXTRA_LATENCY_MODE_ON)
		ovr_performance.set_foveation_level(2);  # 0 == off; 4 == highest

	_performed_runtime_config = true



func _check_move(delta_t):
	var dx=0
	var dy=0
	if $LeftTouchController.get_is_active():
		dx = $LeftTouchController.get_joystick_axis(0)
		dy = $LeftTouchController.get_joystick_axis(1)
	else:
		dx = - Input.get_action_strength("strafe_left") + Input.get_action_strength("strafe_right");
		dy = Input.get_action_strength("walk_forwards") - Input.get_action_strength("walk_backwards");
	var dead_zone = 0.125;
	
	if (dx*dx + dy*dy > dead_zone*dead_zone):
		var view_dir = -$ARVRCamera.transform.basis.z;
		var strafe_dir = $ARVRCamera.transform.basis.x;

		view_dir.y = 0.0;
		strafe_dir.y = 0.0;

		view_dir = view_dir.normalized();
		strafe_dir = strafe_dir.normalized();

		var move_vector = Vector2(dx, dy).normalized() * move_speed;

		# to move the player in VR the position of the ARVROrigin needs to be
		# changed. As this script is attached to the ARVROrigin self is modified here
		self.transform.origin += view_dir * move_vector.y * delta_t;
		self.transform.origin += strafe_dir * move_vector.x * delta_t;




func _start_controller_vibration(controller, duration, rumble_intensity):
	print("Starting vibration of controller " + str(controller) + " for " + str(duration) + "  at " + str(rumble_intensity))
	controllers_vibration_duration[controller.controller_id] = duration
	controller.set_rumble(rumble_intensity)

func _update_controllers_vibration(delta_t):
	# Check if there are any controllers currently vibrating
	if (controllers_vibration_duration.empty()):
		return

	# Update the remaining vibration duration for each controller
	for i in ARVRServer.get_tracker_count():
		var tracker = ARVRServer.get_tracker(i)
		if (controllers_vibration_duration.has(tracker.get_tracker_id())):
			var remaining_duration = controllers_vibration_duration[tracker.get_tracker_id()] - (delta_t * 1000)
			if (remaining_duration < 0):
				controllers_vibration_duration.erase(tracker.get_tracker_id())
				tracker.set_rumble(0)
			else:
				controllers_vibration_duration[tracker.get_tracker_id()] = remaining_duration


func _check_worldscale():
	if was_world_scale != world_scale:
		was_world_scale = world_scale
		var inv_world_scale = 1.0 / was_world_scale
		var controller_scale = Vector3(inv_world_scale, inv_world_scale, inv_world_scale)
		$"LeftTouchController/left-controller".scale = controller_scale
		$"RightTouchController/right-controller".scale = -controller_scale



###########################################################################################
###########################################################################################
#		The rest of this file is just examples of what you can do with the buttons
#		You need to connect signals for the examples to work
###########################################################################################
###########################################################################################


# current button mapping for the touch controller
# godot itself also exposes some of these constants via JOY_VR_* and JOY_OCULUS_*
# this enum here is to document everything in place and includes the touch event mappings
enum CONTROLLER_BUTTON {
	YB = 1,
	GRIP_TRIGGER = 2, # grip trigger pressed over threshold
	ENTER = 3, # Menu Button on left controller

	TOUCH_XA = 5,
	TOUCH_YB = 6,

	XA = 7,

	TOUCH_THUMB_UP = 10,
	TOUCH_INDEX_TRIGGER = 11,
	TOUCH_INDEX_POINTING = 12,

	THUMBSTICK = 14, # left/right thumb stick pressed
	INDEX_TRIGGER = 15, # index trigger pressed over threshold
}


# this is a function connected to the button release signal from the controller
func _on_LeftTouchController_button_pressed(button):
	
	if (button == CONTROLLER_BUTTON.YB):
		# examples on using the ovr api from gdscript
		if (ovr_guardian_system):
			print(" ovr_guardian_system.get_boundary_visible() == " + str(ovr_guardian_system.get_boundary_visible()));
			#ovr_guardian_system.request_boundary_visible(true); # make the boundary always visible

			# the oriented bounding box is the largest box that fits into the currently defined guardian
			# the return value of this function is an array with [Transform(), Vector3()] where the Vector3
			# is the scale of the box and Transform contains the position and orientation of the box.
			# The height is not yet tracked by the oculus system and will be a default value.
			print(" ovr_guardian_system.get_boundary_oriented_bounding_box() == " + str(ovr_guardian_system.get_boundary_oriented_bounding_box()));

		if (ovr_tracking_transform):
			print(" ovr_tracking_transform.get_tracking_space() == " + str(ovr_tracking_transform.get_tracking_space()));

			# you can change the tracking space to control where the default floor level is and
			# how recentring should behave.
			#ovr_guardian_system.set_tracking_space(ovrVrApiTypes.OvrTrackingSpace.VRAPI_TRACKING_SPACE_STAGE);

		if (ovr_utilities):
			print(" ovr_utilities.get_ipd() == " + str(ovr_utilities.get_ipd()));
			print("Primary controller id: " + str(ovr_input.get_primary_controller_id()))

			# you can access the accelerations and velocitys for the head and controllers
			# that are predicted by the Oculus VrApi via these funcitons:
			var controller_id = $LeftTouchController.controller_id;
			print(" ovr_utilities.get_controller_linear_velocity(controller_id) == " + str(ovr_utilities.get_controller_linear_velocity(controller_id)));
			print(" ovr_utilities.get_controller_linear_acceleration(controller_id) == " + str(ovr_utilities.get_controller_linear_acceleration(controller_id)));
			print(" ovr_utilities.get_controller_angular_velocity(controller_id) == " + str(ovr_utilities.get_controller_angular_velocity(controller_id)));
			print(" ovr_utilities.get_controller_angular_acceleration(controller_id) == " + str(ovr_utilities.get_controller_angular_acceleration(controller_id)));

	if (button == CONTROLLER_BUTTON.XA):
		ARVRServer.center_on_hmd(true, true)
		_start_controller_vibration($LeftTouchController, 40, 0.5)

func _on_RightTouchController_button_pressed(button):
	
	if (button == CONTROLLER_BUTTON.YB):
		if (ovr_utilities):
			print("Primary controller id: " + str(ovr_input.get_primary_controller_id()))
			# use this for fade to black for example: here we just do a color change
			ovr_utilities.set_default_layer_color_scale(Color(0.5, 0.0, 1.0, 1.0));

	if (button == CONTROLLER_BUTTON.XA):
		_start_controller_vibration($RightTouchController, 40, 0.5)


func _on_RightTouchController_button_release(button):
	if (button != CONTROLLER_BUTTON.YB): return;

	if (ovr_utilities):
		# reset the color to neutral again
		ovr_utilities.set_default_layer_color_scale(Color(1.0, 1.0, 1.0, 1.0));



func _on_LeftTouchController_button_release(button):
	pass # Replace with function body.