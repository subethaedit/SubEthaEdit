<!DOCTYPE html>
<html>
 <head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 <title>MasterMindCodeBreaker</title>

<style type="text/css" media="screen">
<!--
    body { background-color:#fff; color:#000; padding:8px; margin:0px;}
    img { height:16px;}
-->
</style>
 </head>
 <body>

<%@ page import="mastermind.*"%>     

<%    
//input setup
    int counter = 0;
    StringBuilder history = new StringBuilder();
    String[] letters = new String[4];

    String[] param = new String[4];

    if (request.getParameter("b1") != null && request.getParameter("b1").equals("check")) {

        //getting the values from the request
        if (request.getParameter("s1") != null && request.getParameter("s2") != null && request.getParameter("s3") != null && request.getParameter("s4") != null) {      
        //empty boxes will not be treated any differnt
            for (int i = 0; i < 4; i++) {
                param[i] = request.getParameter("s"+ (i+1));
            }
        } else {
            for (int i = 0; i < 4; i++) {
                param[i] = "";
            }
        }
        
        // getting the last session if any
        session = request.getSession(true);

        if (session.getAttribute("counter") != null) {
            counter = Integer.parseInt(session.getAttribute("counter").toString());
        } else {
            counter = 1;
        }
    
        if (session.getAttribute("letters") != null) {
            letters = (String[])session.getAttribute("letters");
        } else {
            letters = new Generator().getLetters();
            //debug
            //String[] s = {"a", "b", "c", "d"};
            //letters =  s; //debug
        }

        SolverFixed solver;
        if (session.getAttribute("solver") != null) {
            solver = (SolverFixed)session.getAttribute("solver");
        } else {
            solver = new SolverFixed(letters);
        }


        if (session.getAttribute("history") != null) {
            history = (StringBuilder)session.getAttribute("history");
        } else {
            history = new StringBuilder();

            //debug
            history.append("Debug-Information: ");
            for(int i = 0; i < letters.length; i ++) {
                history.append(letters[i]);
                history.append(" ");
            }
            history.append("<br />");
        }
        
        if (counter < 11 && counter > 0) {
            for (String s : param) {
                history.append("<input type=\"text\" size=\"1\" value=\""+ s +"\" readonly=\"readonly\" />");
            }
            
            // check solution
            Pin[] solution = solver.calculatePins(param);
            
            for (Pin s : solution) {
               history.append("<img src=\"images/" + s.toString() + ".png\" />");
            }
            
            history.append(" " + counter + ". Versuch");
            history.append("<br />");
            
        } else {
            if (counter == 11) {
                for (String s : letters) {
                    history.append("<input type=\"text\" size=\"1\" value=\""+ s +"\" />");
                }

                Pin[] solution = solver.calculatePins(letters);
                for (Pin s : solution) {
                   history.append("<img src=\"images/" + s.toString() + ".png\" />");
                }
                history.append(" Lösung");
                history.append("<hr />");

            } else {
                session.invalidate();
            }
        }
        
        if ( counter != 12) { 
        //setting the session
            session.setAttribute("counter", (counter + 1));
            session.setAttribute("letters", letters);
            session.setAttribute("solver", solver);
            session.setAttribute("history", history);
        } 

    } else {
        session.invalidate();
        //neustart des spieles, da keine aussage darüber ob es der selbe code sein soll oder nicht
    }
%>

<p>
    Einen vierstelliger Code soll erraten werden, der aus den Buchstaben A, B, C, D, E, F, G bestehen kann, wobei jeder Buchstabe höchstens einmal vorkommt. <br />
    Nach jedem Rateversuch, bekommt der Benutzer einen Hinweis zu seinem geratenen Code:<br />
    <img src="images/Red.png" /> Ein roter Punkt bedeutet, dass einer der geratenen Buchstaben im Code vorkommt und sich an der richtigen Stelle befindet.<br />
    <img src="images/Black.png" /> Ein schwarzer Punkt bedeutet, dass einer der geratenen Buchstaben im Code vorkommt, aber sich nicht an der richtigen Stelle befindet.<br />
    <img src="images/White.png" /> Ein weißer Punkt bedeutet, dass einer der geratenen Buchstaben nicht im Code vorkommt.
</p>
<hr />
    <form action="indexFixed.jsp" method="get">
        <input name="s1" type="text" size="1" /><input name="s2" type="text" size="1" /><input name="s3" type="text" size="1" /><input name="s4" type="text" size="1" />

        <button type="submit" name="b1" value="check">Check</button>
        <button type="submit" name="b1" value="restart">Restart Game (But with different Code!)</button>
    </form>
    <hr>
    <form>
    <% out.print(history.toString()); %>
    </form>
 </body>
</html>