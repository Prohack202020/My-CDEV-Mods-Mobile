package game.system;

#if android
import flixel.input.android.FlxAndroidKey;
import android.content.Context;
import game.system.native.Android;
#end

import game.cdev.log.GameLog;

import haxe.io.Path;
#if CRASH_HANDLER
import sys.FileSystem;
import sys.io.File;
import haxe.CallStack;
import haxe.CallStack.StackItem;
import openfl.events.UncaughtErrorEvent;
import sys.io.Process;
#end
import game.cdev.engineutils.CDevFPSMem;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxG;
#if desktop
import game.cdev.engineutils.Discord.DiscordClient;
#end
import lime.app.Application;

using StringTools;

class FunkinMain extends Sprite
{
	/** CDEV Engine's Default Game Resolution, it's the best to keep the values the same as the one inside the `Project.xml`. 
	 *	(If you want to change the window size, go to `Project.xml` and edit the window properties there.) 
	 */
    static var DEFAULT_DIMENSION = {
        width: 1280,
        height: 720
    };

    var game = {
		gameWidth: DEFAULT_DIMENSION.width,
		gameHeight: DEFAULT_DIMENSION.height,
		initialState: meta.states.TitleState,
        zoom: 1.0,
        framerate: 60,
        skipSplash: true,
        startFullscreen: false
    };

	public static var fpsCounter:CDevFPSMem;
	public static var cdevLogs:GameLog;
	public static var instance:FunkinMain = null;

	public static var discordRPC:Bool = false;

	var playState:Bool = false;

	public static function main():Void
	{
		trace(FlxG.stage.application.window.width+"x"+FlxG.stage.application.window.height);
		initArgs();
		Lib.current.addChild(new FunkinMain());
	}

	public static function initArgs() { //test
		var args:Array<String> = Sys.args();
		
		if (args.contains("-testmode")){
			trace("test mode triggered");
		}
	}

	public function new()
	{
		super();
		instance = this;

		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		Application.current.window.alert("We detected that CDEV Engine is running on Android target, expect things to crash & unstable.", "Warning");
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		initDeviceWindow(FlxG.stage.application.window.width, FlxG.stage.application.window.height);
		setupGame();
	}

	//a lot of traces, i know.
	public function initDeviceWindow(width:Int, height:Int):Void {
		#if mobile
		trace("Init: Device Window - Mobile");
		FlxG.fullscreen = true;
		trace("Init: Device Window - Fullscreen");
        var targetAspectRatio:Float = width / height; }
	// i just looked into this file again and what the hell is this
	public function isPlayState():Bool { return playState; }

	public function setFPSCap(value:Float) { openfl.Lib.current.stage.frameRate = value; }

	public function getFPS():Float { return fpsCounter.times.length; }

	// uhhh
	#if CRASH_HANDLER
	function onCrash(uncaught:UncaughtErrorEvent):Void
	{
		// somehow, the music crashed the crash handler
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		var textStuff:String = "";
		var filePath:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		filePath = "./crash/" + "CDEV-Engine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					textStuff += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		textStuff += "\nEngine Version: "+CDevConfig.engineVersion;
		textStuff += "\nError: " + uncaught.error;
		#if desktop 
		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(filePath, textStuff + "\n");

		Sys.println("Crash info file saved in " + Path.normalize(filePath));	

		CDevConfig.storeSaveData();
		DiscordClient.shutdown(); 
		#end

		var reportClassic:String = "CDEV Engine crashed during runtime.\n\nCall Stacks:\n"
		+ textStuff
		+ "Please report this error to CDEV Engine's GitHub page: \nhttps://github.com/Core5570RYT/FNF-CDEV-Engine";
		
		#if windows
		var cdev_ch_path:String = "cdev-crash_handler.exe";
		if (FileSystem.exists(cdev_ch_path))
		{
			new Process(cdev_ch_path, ["crash", filePath]);
		}
		else
		#else #if android
		Android.onCrash(reportClassic, "CDEV-Engine_" + dateNow + ".txt");
		#end #end
		{
			// gotta call a simple message box thingie
			Application.current.window.alert(reportClassic);
		}
		Sys.exit(1);
	}
	#end
}
