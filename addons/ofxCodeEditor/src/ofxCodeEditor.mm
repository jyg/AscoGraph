#import "ofxCodeEditor.h"

#import "ScintillaView.h"
#import "ScintillaCocoa.h"
#import "InfoBar.h"

static const int MARGIN_SCRIPT_FOLD_INDEX = 1;

@implementation ofxCodeEditor

- (void) set_normal_keywords: (const char*)normal_keywords_ {
	normal_keywords = normal_keywords_;
}


- (void) set_major_keywords: (const char*)major_keywords_ {
	major_keywords = major_keywords_;
}

- (void) set_procedure_keywords: (const char*)procedure_keywords_ {
	procedure_keywords = procedure_keywords_;
}

- (void) set_system_keywords: (const char*)system_keywords_ {
	system_keywords = system_keywords_;
}


- (void) setup: (NSWindow*) window glview: (NSView*) glview rect: (ofRectangle&) rect {
	NSLog(@"ofxCodeEditor: setup: %.1f, %.1f : %.1fx%.1f", rect.x, rect.y, rect.width, rect.height);
	NSRect r;
	r.origin.x = rect.x;
	r.origin.y = rect.y;
	r.size.width = rect.width;
	r.size.height = rect.height;

	mGLview = glview;
	mWindow = window;
	mEditor = [[[ScintillaView alloc] initWithFrame:r] autorelease];

	[mEditor setOwner:mWindow];
	NSLog(@"ofxEditor: scintillaview allocated");


	[mEditor setBounds:NSMakeRect(0, 0, rect.width, rect.height)];

	//[mEditor setBorderType:NSNoBorder];
	//[mEditor setHasVerticalScroller:YES];
	//[mEditor setHasHorizontalScroller:NO];
	[mEditor setAutoresizingMask:NSViewWidthSizable];
	[glview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];


	NSRect s;
	[window setContentView:nil];
	s = [glview frame]; s.size.width -= rect.width; [ glview setFrame:s];


	s = [glview bounds];
	NSLog(@"ofxEditor: setup: GLView bounds: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);
	s = [glview frame];
	NSLog(@"ofxEditor: setup: GLView frame: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);
	s = [mEditor bounds];
	NSLog(@"ofxEditor: setup: ScintillaView bounds: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);
	s = [mEditor frame];
	NSLog(@"ofxEditor: setup: ScintillaView frame: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);


	s = [[window contentView] bounds];
	NSLog(@"ofxEditor: setup: window bounds: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);
	s = [[window contentView] frame];
	NSLog(@"ofxEditor: setup: window frame: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);


	splitView = [[NSSplitView alloc] initWithFrame:[[window contentView] frame]];
	SplitViewDelegate *splitViewDelegate = [[SplitViewDelegate alloc] init];
	[splitView setVertical:true];

	//CGFloat dividerThickness = [splitView dividerThickness];
	//[scrollview frame].origin.x += dividerThickness; [scrollview frame].size.width -= dividerThickness;
	[splitView setDelegate:splitViewDelegate];
	NSLog(@"ofxEditor: setup: splitview: adding glview");
	[splitView addSubview:glview];// positioned:NSWindowAbove relativeTo:nil];
	NSLog(@"ofxEditor: setup: splitview: adding scintillaview");
	[splitView addSubview:mEditor]; 

	s = [splitView frame];
	NSLog(@"ofxEditor: setup: splitView frame: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);
	s = [splitView bounds];
	NSLog(@"ofxEditor: setup: splitView bounds: %.1f, %.1f : %.1fx%.1f", s.origin.x, s.origin.y, s.size.width, s.size.height);

	NSLog(@"ofxEditor: setup: splitviews subviews count %d, setting splitview to window contentView", [[splitView subviews] count]);
	[window setContentView:splitView];
	NSLog(@"ofxEditor: setup: window subviews count %d", [[[window contentView] subviews] count]);
	//[splitView release];

	[self setupEditor];
}

//--------------------------------------------------------------------------------------------------

typedef void(*SciNotifyFunc) (intptr_t windowid, unsigned int iMessage, uintptr_t wParam, uintptr_t lParam);


/**
 * Initialize scintilla editor (styles, colors, markers, folding etc.].
 */
- (void) setupEditor
{  
	[mEditor setGeneralProperty: SCI_SETLEXER parameter: SCLEX_ANTESCOFO value: (sptr_t) "Antescofo"];
	// alternatively: [mEditor setEditorProperty: SCI_SETLEXERLANGUAGE parameter: nil value: (sptr_t) "mysql"];

	// Number of styles we use with this lexer.
	[mEditor setGeneralProperty: SCI_SETSTYLEBITS value: [mEditor getGeneralProperty: SCI_GETSTYLEBITSNEEDED]];

	// Keywords to highlight. Indices are:
	// 0 - Major keywords (reserved keywords)
	// 1 - Normal keywords (everything not reserved but integral part of the language)
	// 2 - Database objects
	// 3 - Function keywords
	// 4 - System variable keywords
	// 5 - Procedure keywords (keywords used in procedures like "begin" and "end")
	// 6..8 - User keywords 1..3
	if (major_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 0 value: major_keywords];
	if (normal_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 1 value: normal_keywords];
	if (system_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 4 value: system_keywords];
	if (procedure_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 5 value: procedure_keywords];
	if (client_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 6 value: client_keywords];
	if (user_keywords)
		[mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 7 value: user_keywords];

	[mEditor setGeneralProperty: SCI_COLOURISE parameter:-1 value: 0];
	// Colors and styles for various syntactic elements. First the default style.
	//[mEditor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Helvetica"];
	// [mEditor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Monospac821 BT"]; // Very pleasing programmer's font.
	//[mEditor setGeneralProperty: SCI_STYLESETSIZE parameter: STYLE_DEFAULT value: 14];
	//[mEditor setColorProperty: SCI_STYLESETFORE parameter: STYLE_DEFAULT value: [NSColor blackColor]];//

	//[mEditor setGeneralProperty: SCI_STYLECLEARALL parameter: 0 value: 0];	

	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_DEFAULT value: [NSColor blackColor]];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_COMMENT fromHTML: @"#097BF7"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_COMMENTLINE fromHTML: @"#097BF7"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_HIDDENCOMMAND fromHTML: @"#097BF7"];
	[mEditor setColorProperty: SCI_STYLESETBACK parameter: SCE_ANTESCOFO_HIDDENCOMMAND fromHTML: @"#F0F0F0"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_NUMBER fromHTML: @"#7F7F00"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_SQSTRING fromHTML: @"#FFAA3E"];

	// Note: if we were using ANSI quotes we would set the DQSTRING to the same color as the 
	//       the back tick string.
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_DQSTRING fromHTML: @"#274A6D"];

	// Keyword highlighting.


	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_MAJORKEYWORD fromHTML: @"#007F00"];
	[mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_ANTESCOFO_MAJORKEYWORD value: 1];

	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_KEYWORD fromHTML: @"#FF0000"];
	[mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_ANTESCOFO_KEYWORD value: 1];

	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_PROCEDUREKEYWORD fromHTML: @"#0DB01E"];
	//[mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_ANTESCOFO_PROCEDUREKEYWORD value: 1];


	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_VARIABLE fromHTML: @"#ff1111"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_SYSTEMVARIABLE fromHTML: @"#FF0000"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_KNOWNSYSTEMVARIABLE fromHTML: @"#0000A5"];


	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_USER1 fromHTML: @"#808080"];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_USER2 fromHTML: @"#808080"];
	[mEditor setColorProperty: SCI_STYLESETBACK parameter: SCE_ANTESCOFO_USER2 fromHTML: @"#F0E0E0"];

	// The following 3 styles have no impact as we did not set a keyword list for any of them.
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_FUNCTION value: [NSColor redColor]];

	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_IDENTIFIER value: [NSColor blackColor]];
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_ANTESCOFO_QUOTEDIDENTIFIER fromHTML: @"#274A6D"];
	[mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_ANTESCOFO_OPERATOR value: 1];

	// Line number style.
	[mEditor setColorProperty: SCI_STYLESETFORE parameter: STYLE_LINENUMBER fromHTML: @"#F0F0F0"];
	[mEditor setColorProperty: SCI_STYLESETBACK parameter: STYLE_LINENUMBER fromHTML: @"#808080"];

	[mEditor setGeneralProperty: SCI_SETMARGINTYPEN parameter: 0 value: SC_MARGIN_NUMBER];
	[mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 0 value: 40];

	// Markers.
	[mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 1 value: 10];

	[mEditor setLexerProperty: @"braces.check" value: @"1"];

	// Some special lexer properties.
	[mEditor setLexerProperty: @"fold" value: @"1"];
	[mEditor setLexerProperty: @"fold.compact" value: @"1"];
	[mEditor setLexerProperty: @"fold.comment" value: @"1"];
	[mEditor setLexerProperty: @"fold.preprocessor" value: @"1"];

	// Folder setup.
	[mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 2 value: 16];
	[mEditor setGeneralProperty: SCI_SETMARGINMASKN parameter: 2 value: SC_MASK_FOLDERS];
	[mEditor setGeneralProperty: SCI_SETMARGINSENSITIVEN parameter: 2 value: 1];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPEN value: SC_MARK_BOXMINUS];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDER value: SC_MARK_BOXPLUS];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERSUB value: SC_MARK_VLINE];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERTAIL value: SC_MARK_LCORNER];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEREND value: SC_MARK_BOXPLUSCONNECTED];
	[mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPENMID value: SC_MARK_BOXMINUSCONNECTED];
	[mEditor setGeneralProperty : SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERMIDTAIL value: SC_MARK_TCORNER];
	for (int n= 25; n < 32; ++n) // Markers 25..31 are reserved for folding.
	{
		[mEditor setColorProperty: SCI_MARKERSETFORE parameter: n value: [NSColor whiteColor]];
		[mEditor setColorProperty: SCI_MARKERSETBACK parameter: n value: [NSColor blackColor]];
	}

	// Init markers & indicators for highlighting of syntax errors.
	[mEditor setColorProperty: SCI_INDICSETFORE parameter: 0 value: [NSColor redColor]];
	[mEditor setGeneralProperty: SCI_INDICSETUNDER parameter: 0 value: 1];
	[mEditor setGeneralProperty: SCI_INDICSETSTYLE parameter: 0 value: INDIC_SQUIGGLE];

	[mEditor setColorProperty: SCI_MARKERSETBACK parameter: 0 fromHTML: @"#B1151C"];

	[mEditor setColorProperty: SCI_SETSELBACK parameter: 1 value: [NSColor selectedTextBackgroundColor]];

	// Uncomment if you wanna see auto wrapping in action.
	//[mEditor setGeneralProperty: SCI_SETWRAPMODE parameter: SC_WRAP_WORD value: 0];

	InfoBar* infoBar = [[[InfoBar alloc] initWithFrame: NSMakeRect(0, 0, 400, 0)] autorelease];
	[infoBar setDisplay: IBShowAll];
	[mEditor setInfoBar: infoBar top: NO];

	[mEditor setGeneralProperty: SCI_SETTABWIDTH parameter: 4 value: 0];
	[mEditor setStatusText: @"Operation complete"];
}


- (void) setWrapMode:(bool)mode
{
	[mEditor setGeneralProperty: SCI_SETWRAPMODE parameter:mode value:mode];
}


//--------------------------------------------------------------------------------------------------

/* XPM */
static const char * box_xpm[] = {
	"12 12 2 1",
	" 	c None",
	".	c #800000",
	"   .........",
	"  .   .   ..",
	" .   .   . .",
	".........  .",
	".   .   .  .",
	".   .   . ..",
	".   .   .. .",
	".........  .",
	".   .   .  .",
	".   .   . . ",
	".   .   ..  ",
	".........   "};

/*
- (void) showAutocompletion
{
	const char *words = normal_keywords;
	[mEditor setGeneralProperty: SCI_AUTOCSETIGNORECASE parameter: 1 value:0];
	[mEditor setGeneralProperty: SCI_REGISTERIMAGE parameter: 1 value:(sptr_t)box_xpm];
	const int imSize = 12;
	[mEditor setGeneralProperty: SCI_RGBAIMAGESETWIDTH parameter: imSize value:0];
	[mEditor setGeneralProperty: SCI_RGBAIMAGESETHEIGHT parameter: imSize value:0];
	char image[imSize * imSize * 4];
	for (size_t y = 0; y < imSize; y++) {
		for (size_t x = 0; x < imSize; x++) {
			char *p = image + (y * imSize + x) * 4;
			p[0] = 0xFF;
			p[1] = 0xA0;
			p[2] = 0;
			p[3] = x * 23;
		}
	}
	[mEditor setGeneralProperty: SCI_REGISTERRGBAIMAGE parameter: 2 value:(sptr_t)image];
	[mEditor setGeneralProperty: SCI_AUTOCSHOW parameter: 0 value:(sptr_t)words];
}
*/

- (void) searchNext: (string) str
{
  int searchFlags= 0;
  /*if (matchCase)
    searchFlags |= SCFIND_MATCHCASE;
  if (wholeWord)
    searchFlags |= SCFIND_WHOLEWORD;
    */

  /*
  NSString *text = [NSString stringWithUTF8String:str.c_str() ];

      bool result = [ mEditor directCall:mEditor
                                 message: SCI_SEARCHNEXT
                                  wParam: searchFlags
                                  lParam: (sptr_t) text];

      if (result)
	      [self setGeneralProperty: SCI_SCROLLCARET value: 0];
	      */
}

-(int) searchNreplaceText:(string)str str2:(string)str2
{
	NSString *text1 = [NSString stringWithUTF8String:str.c_str() ];
	NSString *text2 = [NSString stringWithUTF8String:str2.c_str() ];
	cout << "CodeEditor: will searchNreplace for text: " << str << " with text:" << str2 << endl;

	int res = [ mEditor findAndReplaceText: text1
			    	        byText: text2
				     matchCase: NO
				     wholeWord: NO
					 doAll: YES];
	cout << "searchNreplace Text: res:" << res << endl;
	return res;
}

- (string) getSelection
{
	long matchStart = [mEditor getGeneralProperty: SCI_GETSELECTIONSTART parameter: 0];
	long matchEnd = [mEditor getGeneralProperty: SCI_GETSELECTIONEND parameter: 0];

	long n = matchEnd - matchStart;
	cout << "getSelection: n=" << n << " start:" << matchStart << " end:" << matchEnd << endl;

	if (n > 0) {
		char cstr[n];
		//[mEditor getGeneralProperty:SCI_GETSELTEXT parameter:(sptr_t)cstr];
		[ScintillaView directCall:mEditor message:SCI_GETSELTEXT wParam:(uptr_t)(0) lParam:(sptr_t)cstr];
		string ret(cstr);
		return ret;
	}
	return string("");
}

- (void) braceMatch //:  (int) pos
{
	int pos = [mEditor getGeneralProperty:SCI_GETCURRENTPOS];
	cout << pos << endl;
	int pm = (int)[mEditor getGeneralProperty:SCI_BRACEMATCH parameter:pos];
	//cout << "pm= " << pm << endl;
}


- (void) searchText: (string) str
{
	NSString *text = [NSString stringWithUTF8String:str.c_str() ];
	cout << "CodeEditor: will search for text: " << str.c_str() << endl;

	bool res = [mEditor findAndHighlightText: text
			matchCase: NO
			wholeWord: NO
			scrollTo: YES
			wrap: YES
			//backwards: YES];
			backwards: NO];

	//if (!res) return;
	long matchStart = [mEditor getGeneralProperty: SCI_GETSELECTIONSTART parameter: 0];
	long matchEnd = [mEditor getGeneralProperty: SCI_GETSELECTIONEND parameter: 0];
	[mEditor setGeneralProperty: SCI_FINDINDICATORFLASH parameter: matchStart value:matchEnd];
	cout << "searchText: " << str << "-->"<< matchStart<< ":" << matchEnd << endl;
	//[ self showLine:matchStart lineb:matchEnd ];

	//if ([[searchField stringValue] isEqualToString: @"XX"]) [self showAutocompletion];
}

- (void) die {
	NSRect s = [mWindow frame];
	s.size.width -= 400;
	[ mGLview setFrame:s ];
	[ mWindow setContentView:mGLview ];
	//[ splitView release ];
}


// load text
//void ofxCodeEditor::loadFile(string filename)
- (void) loadFile: (string) filename
{
	cout << "ofxCodeEditor: loadfile:" << filename << endl;
	NSError* error = nil;

	NSString* path = [[NSBundle mainBundle] pathForResource: [NSString stringWithUTF8String:filename.c_str()]//@"TestData" 
		ofType: @"" inDirectory: nil];

	NSString* sql = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:filename.c_str()]
		encoding:NSUTF8StringEncoding
		error: &error];
	if (error && [[error domain] isEqual: NSCocoaErrorDomain])
		NSLog(@"%@", error);

	[mEditor setString: sql];
	if (!error)
		[mWindow setTitle:[NSString stringWithUTF8String:filename.c_str()]];
	[self setupEditor];
}

- (void) scrollLine: (int) line
{
	[mEditor setGeneralProperty: SCI_LINESCROLL parameter:0 value:line];
}

- (int) getMaxLines
{
	return [mEditor getGeneralProperty:SCI_LINESONSCREEN];
}

- (int) getCurrentPos
{
	return [mEditor getGeneralProperty:SCI_GETCURRENTPOS];

}
- (int) getCurrentLine
{
	return [mEditor getGeneralProperty:SCI_LINEFROMPOSITION parameter:[mEditor getGeneralProperty:SCI_GETCURRENTPOS]];

}


- (void) setCurrentPos:(int)pos
{
	[mEditor setGeneralProperty:SCI_SETCURRENTPOS parameter:pos value:pos];
	[mEditor setGeneralProperty:SCI_SETSEL parameter:pos value:pos];
	[mEditor setGeneralProperty:SCI_SCROLLCARET parameter:pos value:pos];

}

- (void) clear
{
	[mEditor setString: @""];
	[mWindow setTitle: @""];
}

- (int) modified
{
	return [mEditor getGeneralProperty:SCI_GETMODIFY];
}



- (void) gotoPos: (int) pos
{
	[mEditor setGeneralProperty:SCI_GOTOPOS parameter:pos value:pos];
	/*
	[mEditor setGeneralProperty:SCI_SETANCHOR parameter:pos value:pos];
	[mEditor setGeneralProperty:SCI_SETCURRENTPOS parameter:pos value:pos];
	*/
	[mEditor setGeneralProperty:SCI_SETSEL parameter:pos value:pos];


}

//void ofxCodeEditor::showLine(int linea, int lineb)
- (void) showLine: (int) linea lineb:(int)lineb cola:(int)cola colb:(int)colb
{
	//[mEditor mBackend]->ScrollText(-1000); [mEditor mBackend]->ScrollText(linea);

	cout << "ofxCodeEditor: showLine: " << linea << ":"<< cola << " -> " << lineb << ":"<< colb << endl;
	// line scroll ok
	[mEditor setGeneralProperty: SCI_LINESCROLL parameter:0 value:0];
	[mEditor setGeneralProperty: SCI_LINESCROLL parameter:0 value:linea];

	[mEditor setGeneralProperty: SCI_CLEARSELECTIONS value:0];

	[mEditor setGeneralProperty: SCI_SETSEL 
		parameter: [mEditor getGeneralProperty: SCI_FINDCOLUMN parameter:lineb extra:colb]
		value: [mEditor getGeneralProperty: SCI_FINDCOLUMN parameter:linea extra:cola]];
}

- (void) showLine: (int) linea lineb: (int) lineb
{
	//[mEditor mBackend]->ScrollText(-1000); [mEditor mBackend]->ScrollText(linea);

	//cout << "ofxCodeEditor: showLine: " << linea << ":" << lineb << endl;
	// line scroll ok
	[mEditor setGeneralProperty: SCI_LINESCROLL parameter:0 value:0];
	[mEditor setGeneralProperty: SCI_LINESCROLL parameter:0 value:linea];

	[mEditor setGeneralProperty: SCI_CLEARSELECTIONS value:0];

	[mEditor setGeneralProperty: SCI_SETSEL 
		parameter: [mEditor getGeneralProperty: SCI_FINDCOLUMN parameter:lineb]
		value: [mEditor getGeneralProperty: SCI_FINDCOLUMN parameter:linea]];
}
- (int) getNbLines
{
	return [mEditor getGeneralProperty: SCI_GETLINECOUNT];
}


- (int) getLenght
{
	return [mEditor getGeneralProperty: SCI_GETLENGTH];
}


- (void) getEditorContent: (string&) content
{
	int n = [self getLenght];
	if (n) {
		cout << "ofxCodeEditor : content len: " << n << endl;
		char cstr[n];

		[ScintillaView directCall:mEditor message:SCI_GETTEXT wParam:(uptr_t)(n+1) lParam:(sptr_t)cstr];
		if (cstr) {
			//[ mEditor setGeneralProperty: SCI_SETSAVEPOINT value:0]; // mark the file saved : TODO wait until antescofo parsing is OK ?
			content = cstr;
		}
	}
}

- (void) replaceString:(int)linea lineb:(int)lineb cola:(int)cola colb:(int)colb str:(const char*)str
{
	cout << "editor::replacestring: from " << linea << ":" << cola << " -> " << lineb << ":" << colb << endl;
	[ self showLine:linea lineb:lineb cola:cola colb:colb];
	[ mEditor setGeneralProperty: SCI_REPLACESEL parameter:0 value:(long)str ];
	//[ self showLine:linea lineb:lineb ];
}

- (void) replaceString:(int)linea lineb:(int)lineb str:(const char*)str
{
	cout << "editor::replacestring: from " << linea << " to " << lineb << endl;
	[ self showLine:linea lineb:lineb ];
	[ mEditor setGeneralProperty: SCI_REPLACESEL parameter:0 value:(long)str ];
	//[ self showLine:linea lineb:lineb ];
}

- (void) insertStringAtPos:(int)posa posb:(int)posb str:(const char*)str;
{
	cout << "editor::insertstringAtPos: from " << posa << " to " << posb << endl;
	//[ self gotopos:posa ];
	[ mEditor setGeneralProperty: SCI_INSERTTEXT parameter:posa value:(long)str ];
	//[ self showLine:linea lineb:lineb ];
}
@end


@implementation SplitViewDelegate

#define kMinOutlineViewSplit    120.0f

// -------------------------------------------------------------------------------
//  splitView:constrainMinCoordinate:
//
//  What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//  splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//  splitView:resizeSubviewsWithOldSize:
//
//  Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{ 
	NSLog(@"resizeSubviewsWithOldSize: oldSize: w:%.1f h:%.1f", oldSize.width, oldSize.height);
	NSRect newFrame = [sender frame]; // get the new size of the whole splitView
	NSLog(@"resizeSubviewsWithOldSize: subviews count: %d", [[sender subviews] count]);
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	CGFloat dividerThickness = [sender dividerThickness];

	leftFrame.size.height = newFrame.size.height;

	if ([[sender subviews] count] >= 2)
	{
		NSView *right = [[sender subviews] objectAtIndex:1];
		NSRect rightFrame = [right frame];
		NSLog(@"resizeSubviewsWithOldSize 2 is good !");
		rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
		rightFrame.size.height = newFrame.size.height;
		rightFrame.origin.x = leftFrame.size.width + dividerThickness;
		[right setFrame:rightFrame];
	} else {
		NSLog(@"resizeSubviewsWithOldSize: error only one view present in NSSplitView");
		leftFrame = newFrame;
		//leftFrame.size.width -= dividerThickness;
	}
	[left setFrame:leftFrame];
}


@end


