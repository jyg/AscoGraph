//
//  ofxAntescofoSim.h
//  part of AscoGraph : graphical editor for Antescofo musical scores.
//
//  Created by Thomas Coffy on 06/12/12.
//  Licensed under the Apache License : http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

#include <iostream>
#include <list>
#include "ofxAntescofog.h"
#include "ofxTimeline.h"
#include "ofxTLTrack.h"
#include "Score.h"
#include "Action.h"

class ofxAntescofog;
class Score;
class ofxTLAntescofoNote;
class Curve;
class ActionRect;
class BeatCurve;
class action_trace;

using namespace std;



class ofxTLAntescofoSim : public ofxTLTrack
{
	public:
		ofxTLAntescofoSim(ofxAntescofog* Antescofog);
		~ofxTLAntescofoSim();

		friend class ofxTLAntescofoNote;

		virtual void setup();
		virtual void draw();
		virtual void update();

		virtual bool mousePressed(ofMouseEventArgs& args, long millis);
		virtual void mouseMoved(ofMouseEventArgs& args, long millis);
		virtual void mouseDragged(ofMouseEventArgs& args, long millis);//bool snapped);
		virtual void mouseReleased(ofMouseEventArgs& args, long millis);

		virtual void keyPressed(ofKeyEventArgs& args);
		
		void windowResized(int w, int h);

		virtual void save();
		virtual void load();
		ofRange getZoomBounds() { return zoomBounds; }
		
		void setNoteTrack(ofxTLAntescofoNote* o) { ofxAntescofoNote = o; }
		ofxTLAntescofoNote *ofxAntescofoNote;

		int get_x(float beat);

		void add_action(action_trace* at);
		void clear_actions();

		ofTrueTypeFont mFont;
		Score *mScore;
		ofxAntescofog *mAntescofog;

		vector<action_trace*> actions;

		bool bEditorShow;
};

