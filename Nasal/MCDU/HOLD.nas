var holdPage = {
	title: [nil, nil, nil],
	subtitle: [nil, nil],
	fontMatrix: [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]],
	arrowsMatrix: [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]],
	arrowsColour: [["ack", "ack", "ack", "ack", "ack", "ack"],["ack", "ack", "ack", "ack", "ack", "ack"]],
	L1: [nil, nil, "ack"], # content, title, colour
	L2: [nil, nil, "ack"],
	L3: [nil, nil, "ack"],
	L4: [nil, nil, "ack"],
	L5: [nil, nil, "ack"],
	L6: [nil, nil, "ack"],
	C1: [nil, nil, "ack"],
	C2: [nil, nil, "ack"],
	C3: [nil, nil, "ack"],
	C4: [nil, nil, "ack"],
	C5: [nil, nil, "ack"],
	C6: [nil, nil, "ack"],
	R1: [nil, nil, "ack"],
	R2: [nil, nil, "ack"],
	R3: [nil, nil, "ack"],
	R4: [nil, nil, "ack"],
	R5: [nil, nil, "ack"],
	R6: [nil, nil, "ack"],
	scroll: 0,
	vector: [],
	index: nil,
	computer: nil,
	inbcrs: nil,
    turn:"R",	
	modified:false,
	holdingfix:false,
	new: func(computer, waypoint) {
		var hp = {parents:[holdPage]};
		hp.computer = computer;
		hp.waypoint = waypoint;
		hp.holdingfix = (waypoint.fly_type == "Hold") ? true : false;
		hp._setupPageWithData();
		hp.updateTmpy();
		return hp;
	},
	del: func() {
		return nil;
	},
	_setupPageWithData: func() {
		me.title = ["HOLD", " AT ", me.waypoint.wp_name];
		me.titleColour = "wht";
		me.arrowsMatrix = [[0, 0, 0, 0, 0, 1], [1, 1, 0, 0, 0, 0]];
		me.arrowsColour = [["ack", "ack", "ack", "ack", "ack", "wht"], ["wht", "wht", "ack", "ack", "ack", "ack"]];
		me.fontMatrix = [[1, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]];
		if (me.waypoint.fly_type == "Hold") {
			me.makeTmpy();
			me.L1 = [" " ~ sprintf("%03.0f", me.waypoint.hold_inbound_radial), "INB CRS", "blu"];
			me.fontMatrix[0][0] = 0;
			
			if (me.waypoint.hold_is_left_handed) {
				me.L2 = [" L", " TURN", "blu"];
			} else {
				me.L2 = [" R", " TURN", "blu"];
			}
			
			if (me.waypoint.hold_is_distance) {
				me.L2 = [" -.-/" ~ me.waypoint.hold_time_or_distance, "TIME/DIST", "blu"];
			} else {
				me.L2 = [" " ~ sprintf("%3.1f", (me.waypoint.hold_time_or_distance / 60)) ~ "/----", "TIME/DIST", "blu"];
			}
			me.R1 = ["COMPUTED ", nil, "wht"];
			me.R2 = ["DATABASE ", nil, "yel"];
			me.arrowsMatrix[1][1] = 0;
		} else {
			if (me.inbcrs == nil) me.L1 = [" [   ]g", "INB CRS", "blu"];
			else me.L1 = [sprintf(" %03.0fg", me.inbcrs), "INB CRS", "blu"];
			if (me.turn == "L") {
				me.L2 = [" L", " TURN", "blu"];
			} else {
				me.L2 = [" R", " TURN", "blu"];
			}
			if (pts.Instrumentation.Altimeter.indicatedFt.getValue() >= 14000) {
				me.L2 = [" 1.5/----", "TIME/DIST", "blu"];
			} else {
				me.L2 = [" 1.0/----", "TIME/DIST", "blu"];
			}
			me.R1 = ["COMPUTED ", nil, "wht"];
			me.R2 = ["DATABASE ", nil, "wht"];
		}
		me.L6 = [" RETURN", nil, "wht"];
		me.C4 = ["LAST EXIT", nil, "wht"];
		me.C5 = ["----  ---.-", "UTC    FUEL", "wht"];
		canvas_mcdu.pageSwitch[me.computer].setBoolValue(0);
	},
	makeTmpy: func() {
		if (!fmgc.flightPlanController.temporaryFlag[me.computer]) {
			fmgc.flightPlanController.createTemporaryFlightPlan(me.computer);
		}
	},
	updateTmpy: func() {
		if (fmgc.flightPlanController.temporaryFlag[me.computer]) {
			me.L1[2] = "yel";
			me.L2[2] = "yel";
			me.L6 = [" F-PLN", " TMPY", "yel"];
			me.R6 = ["INSERT ", " TMPY", "yel"];
			me.arrowsColour[0][5] = "yel";
			me.titleColour = "yel";
			canvas_mcdu.pageSwitch[me.computer].setBoolValue(0);
		} else {
			me.L1[2] = "blu";
			me.L2[2] = "blu";
			me.L6 = [" RETURN", nil, "wht"];
			me.R6 = [nil, nil, "ack"];
			me.arrowsColour[0][5] = "wht";
			me.titleColour = "wht";
			canvas_mcdu.pageSwitch[me.computer].setBoolValue(0);
		}
	},

	addHoldingFix: func(i,wpfix) {

        var wp = nil;

		var wpidx = fmgc.flightPlanController.flightplans[i].indexOfWP(wpfix);
		if (wpidx == -1) {
			var wp = createWP(wpfix.wp_lat(), wpfix.wp_lon(), wpfix.wp_name~"*");
			if (wp != nil) {
				wp.fly_type = "Hold";
				wp.hold_is_left_handed = (me.turn == "L") ? true : false;
				wp.hold_inbound_radial_deg = (me.inbcrs != nil) ? me.inbcrs : wpfix.leg_bearing;
				fmgc.flightPlanController.flightplans[i].addWPToPos(wp,wpidx+1);
				wp = fmgc.flightPlanController.flightplans[i].getWP(wpidx+1); # get new holding wp
				#wp.setAltitude(me.waypoint.alt_cstr,"computed");
				wp.setAltitude(fmgc.FMGCInternal.altSelected,"computed"); # CHECKME - desidered alt
				
				var requestedkts = 230; # below FL140
				if (getprop("/it-autoflight/input/spd-managed")) {
					requestedkts = (fmgc.Input.ktsMach.getValue()) ? math.floor(getprop("/it-autoflight/input/mach") * 661.4708) : int(getprop("/it-autoflight/input/kts")); 
				} else {
					if (fmgc.FMGCInternal.altSelected >= 20000) requestedkts = 265;
					else if (fmgc.FMGCInternal.altSelected >= 14000) requestedkts = 240;
				}
				wp.setSpeed(requestedkts,"computed");
			}
		}
		
		return wp;

	},

	onButtonSelected: func(btn,i) {

		var scratchpad = mcdu_scratchpad.scratchpads[i].scratchpad;		

		if (btn == "L1") {		
			if (scratchpad == "CLR") {
				me.inbcrs = nil;
			} else {
				var ci = math.mod(int(scratchpad),360);
				if (ci != i) return nil;
				me.inbcrs = ci;
			}
		}
		else if (btn == "L2") {
			if (scratchpad == "L" or scratchpad == "R") {
				me.turn = scratchpad;
			} else {
				return nil;
			}
		else if (btn == "R1") {
			if (!me.holdingfix) {
				me.makeTmpy();
				me.holdingfix = me.addHoldingFix(i,me.waypoint);
				if (me.holdingfix != nil) {
					canvas_mcdu.myHold[i].del();
					canvas_mcdu.myHold[i] = holdPage.new(i,wp);
					return "HOLD";
				}
			}
		}
		else return nil;

		return "1";
	}
};