// $Id: PDFPage.java,v 1.10 2003/10/31 18:23:45 mike Exp $

package org.faceless.pdf;

import java.util.*;
import java.io.*;

/**
 * <p>
 * This class represents a single page in a PDF document. This class
 * takes care of drawing shapes, text and images to the document.
 * </p>
 *
 * <b>1. Geometry</b>
 * <p>
 * By default, the geometry of a PDF page is measured in points (defined in
 * PostScript as 1/72 of an inch), from the bottom-left hand corner of the page.
 * This can be altered by calling the <code>setCanvas</code> method as shown
 * here.</p>
 * <p>All methods which specify a rectangle on the page take both corners
 * of the rectangle as parameters, rather than one corner plus the width and
 * height. This is less ambiguous when a page can be measured in different
 * directions.
 * </p>
 * <pre>
 *    // Create a canvas measured from the top-left of the page
 *    // in points, with a 100 point margin around it to the edge
 *    // of the page.
 *    //
 *    PDFPage page = pdf.newPage(800,500);
 *    page.setCanvas(100, 100, 600, 300, POINTS, PAGETOP+PAGELEFT);
 *    page.drawText("This is 100 points from the left and top of the page", 0, 0);
 * </pre>
 *
 * <b>2. Drawing shapes</b>
 * <p>
 * Geometric shapes are drawn using either the simple "draw" methods or
 * the more powerful "path" methods. Whether the shape is filled or just
 * drawn as an outline depends on the <code>FillColor</code>
 * and <code>LineColor</code> of the current style.
 * <ul>
 * <li><b><code>drawLine, drawRectangle, drawPolygon, drawEllipse,</code></b>
 * and (since 1.1) <b><code>drawCircle, drawCircleArc, drawEllipseArc,
 * drawRoundedRectangle</code></b>: These methods draw simple shapes onto the
 * page with a single method call.
 * <pre>
 *    PDFPage page = pdf.newPage(PAGESIZE_A4);
 *    PDFStyle linestyle = new PDFStyle();
 *    linestyle.setLineColor(java.awt.Color.red);
 *
 *    // Draw a rectangle with two diagonal lines inside it.
 *    page.setStyle(linestyle);
 *    page.drawRectangle(100,100, 300, 200);	// Box
 *    page.drawLine(100,100, 400, 300);		// Diagonal 1
 *    page.drawLine(100,300, 400, 100);		// Diagonal 2
 * </pre>
 </li>
 * <li><b><code>pathMove, pathLine, pathBezier, pathClose</code></b>, and (since 1.1)
 * <code><b>pathArc</code></b>: These more primitive methods allow greater
 * control over the creation of geometric shapes, by creating a "path" which
 * can then be drawn with the <code>pathPaint</code> method.
 * <pre>
 *    PDFPage page = pdf.newPage(PAGESIZE_A4);
 *    PDFStyle linestyle = new PDFStyle();
 *    linestyle.setLineColor(java.awt.Color.red);
 *
 *    // Draw the same rectangle with two diagonal lines inside it.
 *    page.setStyle(linestyle);
 *    page.pathMove(100,100);	// Start Box
 *    page.pathLine(100,300);
 *    page.pathLine(400,300);
 *    page.pathLine(400,100);
 *    page.pathLine(100,300);	// Diagonal 1
 *    page.pathPaint();		// Paint the box and the first diagonal
 *    page.pathMove(100,100);	// Start Diagonal 2
 *    page.pathLine(400,300);
 *    page.pathPaint();		// Paint the second diagonal
 * </pre>
 * </ul>
 * </p>
 *
 * <b>3. Drawing Text</b>
 * <p>
 * <ul>
 * <li>A single lines of text can be drawn at a specified location by using the
 * <b><code>drawText</code></b> method.
 * <pre>
 *    PDFPage page = pdf.newPage(PAGESIZE_A4);
 *    PDFStyle textstyle = new PDFStyle();
 *    textstyle.setFillColor(java.awt.Color.black);
 *    textstyle.setFont(new StandardFont(StandardFont.COURIER), 12);
 *
 *    // Draw some text at the specified location
 *    page.setStyle(textstyle);
 *    page.drawText("This is some text", 100, 100);
 * </pre>
 * <li>Larger blocks of text can be drawn by calling <b><code>beginText</code></b>,
 * followed by one or more calls to <b><code>drawText</code></b>, and closing with
 * a call to <b><code>endText</code></b>.
 * This method can be used to mix several styles, even different fonts, in a single
 * paragraph, and since 1.1 the methods <code>beginTextLink</code> and
 * <code>endTextLink</code> can turn portions of the text into HTML-like hyperlinks.
 * <pre>
 *    PDFPage page = pdf.newPage(PAGESIZE_A4);	// 595 x 842 points
 *
 *    // Create first style - 12pt black Helvetica
 *    PDFStyle style1 = new PDFStyle();
 *    style1.setFillColor(java.awt.Color.black);
 *    style1.setFont(new StandardFont(StandardFont.HELVETICA), 12);
 *
 *    // Create second style - 12pt black Verdana (TrueType font)
 *    PDFStyle style2 = (PDFStyle)style1.clone();
 *    PDFFont ver = new TrueTypeFont(new FileInputStream("verdana.ttf"), true, true);
 *    style2.setFont(ver, 12);
 *
 *    // Create an action to perform when the user clicks on the word "hyperlink".
 *    PDFAction action = PDFAction.goToURL(new java.net.URL("http://big.faceless.org"));
 *
 *    // Draw some text. Use the whole page, less a 100 point margin.
 *    page.beginText(100,100, page.getWidth()-100, page.getHeight()-100);
 *
 *    page.setStyle(style1);
 *    page.drawText("This text is in ");
 *    page.setStyle(style2);
 *    page.drawText("Verdana.\n");
 *
 *    page.setStyle(style1);
 *    page.drawText("And this text is a ");
 *    page.beginTextLink(action, null);
 *    page.drawText("hyperlink");
 *    page.endTextLink();
 *
 *    page.endText(false);
 * </pre>
 * </p>
 *
 * <b>4. Drawing Images</b>
 * <p>
 * Bitmap images are drawn using the <b><code>drawImage</code></b> method.
 * <pre>
 *   PDFImage img = new PDFImage(new FileInputStream("mypicture.jpg"));
 *   page.drawImage(img, 100, 100, 200, 200);
 * </pre>
 * </p>
 *
 * <b>5. Transformations</b>
 * <p>
 * As well as adding graphic elements to the page, adjustments can be made to the
 * page itself. A page can be rotated, offset by an amount or scaled in the X and Y
 * directions by calling the <b><code>rotate</code></b>,
 * <b><code>translate</code></b> and <b><code>scale</code></b> methods.
 * These methods affect all operations on the page, like drawing lines or text, and
 * also cause any future transformations to be transformed. This can be confusing.
 * For example:
 * <pre>
 *   page.rotate(0,0,90);
 *   page.translate(0,100);
 * </pre>
 * This section of code first rotates the page 90 degrees clockwise around (0,0), then
 * translates the page by 100 points in the Y axis. Because the page has been rotated
 * 90 degrees, the <code>translate</code> actually has the effect of moving all future
 * operations 100 points <i>to the right</i>, rather than 100 points up the page. The
 * order that transformations are made in is consequently very important.
 * </p>
 *
 * <b>6. Save, Restore and Undo</b>
 * <p>
 * Three further operations simplify page layout, especially when using transformations.
 * The <b><code>save</code></b> and <b><code>restore</code></b> methods allow you to
 * backup and restore the state of a page, and since 1.1 the <b><code>undo</code></b>
 * method allows you to restore the page to the state before the last call to
 * <code>save</code>. It's often a good idea to save the page stage before applying any
 * transformations, so you can quickly get back to exactly the way it was before.
 * <pre>
 *   page.save();		// Save the page before we mess it up.
 *   page.translate(100,200);
 *   page.rotate(300,100,45);
 *   page.setStyle(weirdstyle);
 *     .
 *     .
 *   page.restore();		// Everything is now as it was.
 * </pre>
 * </p>
 *
 * <b>7. Clipping</b>
 * <p>
 * Similar to the <tt>drawRectangle</tt>, <tt>drawCircle</tt> etc. methods above, the
 * <tt>clipRectangle</tt>, <tt>clipRoundedRectangle</tt>, <tt>clipCircle</tt>,
 * <tt>clipEllipse</tt> and <tt>clipPolygon</tt> methods can be used to set the current
 * <i>clipping area</i> on the page. Any future graphics or text operations will only
 * take place inside that clipping area, which defaults to the entire page. For finer
 * control, a path can be drawn using the <tt>path</tt> methods demonstrated above,
 * and the <tt>pathClip</tt> method used to set the clipping area.
 * </p><p>
 * There is no way to enlarge the current clipping area, or to set a new clipping area
 * without reference to the current one. However, as the current clipping area is part
 * of the graphics state, it can (and should) be nested inside calls to <tt>save</tt>
 * and <tt>restore</tt> to limit its effect.
 * </p><p>Here's an example which draws an image on the page, clipped to a circle.</p>
 * <pre>
 *   page.save();		// Save the current clipping path - the whole page
 *
 *   PDFImage img = new PDFImage(new FileInputStream("mypicture.jpg"));
 *   page.clipEllipse(100,100,300,300);
 *   page.drawImage(img, 100, 100, 300, 300);
 *
 *   page.restore();		// Restore the previous clipping path
 * </pre>
 *
 * @see PDFStyle
 * @see PDFFont
 * @see PDFImage
 * @see PDF
 * @version $Revision: 1.10 $
 *
 */
public final class PDFPage extends PeeredObject
{
    final org.faceless.pdf2.PDFPage page;
    private PDFStyle tempstyle;
    private State state;
    private Stack statestack;
    private float translatex, translatey, scalex, scaley, canvaswidth, canvasheight;

    private class State
    {
        float translatex, translatey, scalex, scaley;
	public State()
	{
	    scalex=scaley=1;
	}
    }


    /**
     * Argument to <code>setFilter</code> to compress the page using the
     * <code>java.util.zip.Deflater</code> filter (the default).
     */
    public static final int FILTER_FLATE = 0;

    /**
     * Argument to <code>setFilter</code> to not compress the page.
     */
    public static final int FILTER_NONE = 0;

    /**
     * Argument to <code>setCanvas</code> to measure the page in inches
     */
    public static final int INCHES=4;

    /**
     * Argument to <code>setCanvas</code> to measure the page in centimeters
     */
    public static final int CM=8;

    /**
     * Argument to <code>setCanvas</code> to measure the page in millimeters
     */
    public static final int MM=12;

    /**
     * Argument to <code>setCanvas</code> to measure the page in picas (1 pica=12 points)
     */
    public static final int PICAS=16;

    /**
     * Argument to <code>setCanvas</code> to measure the page in percent. Unlike
     * the other measurements, this can result in changes to the aspect ratio.
     * (10% of the page width is usually less than 10% of the page height).
     */
    public static final int PERCENT=20;

    /**
     * Argument to <code>setCanvas</code> to measure the page in points (the default)
     */
    public static final int POINTS=24;

    /**
     * Argument to <code>setCanvas</code> to measure the page from the bottom
     */
    public static final int PAGEBOTTOM=0;

    /**
     * Argument to <code>setCanvas</code> to measure the page from the top
     */
    public static final int PAGETOP=1;

    /**
     * Argument to <code>setCanvas</code> to measure the page from the left
     */
    public static final int PAGELEFT=0;

    /**
     * Argument to <code>setCanvas</code> to measure the page from the right
     */
    public static final int PAGERIGHT=2;

    /**
     * Barcode type for <code>drawBarCode</code> representing a "Code 39" barcode.
     * This barcode can display digits, the 26 upper-case letters, the space character
     * and the symbols '-', '+', '/', '.', '$' and '%'.
     */
    public static final int BARCODE39=0;

    /**
     * Barcode type for <code>drawBarCode</code> representing a "Code 39" barcode, with
     * checksum. This barcode can display digits, the 26 capital letters, the space character
     * and the symbols '-', '+', '/', '.', '$' and '%'. The checksum algorithm is described
     * on <a target=_new href="http://www.adams1.com/pub/russadam/39code.html">this page</a>.
     */
    public static final int BARCODE39CHECKSUM=1;

    /**
     * Barcode type for <code>drawBarCode</code> representing an
     * "Interleaved 2 of 5" barcode. The interleaved 2 of 5 barcode
     * is only suitable for numbers, and requires an even number of
     * digits (a leading "0" will be automatically added if required).
     */
    public static final int BARCODE25=2;

    /**
     * Barcode type for <code>drawBarCode</code> representing an "Interleaved 2 of 5" barcode,
     * with checksum. The interleaved 2 of 5 barcode is only suitable for numbers and requires
     * an even number of digits including the checksum digit - a leading "0" will be
     * automatically added if required. The checksum digit is added at the end, and is the
     * value of the equation <tt>(10 - ((s[0]*3 + s[1] + s[2]*3 + s[3] <i><small>and so on,
     * multiplying every second digit by 3</small></i>) % 10)) % 10 </tt>
     */
    public static final int BARCODE25CHECKSUM=3;

    /**
     * Barcode type for <code>drawBarCode</code> representing the "Extended Code 39" barcode.
     * This barcode can display all the characters in the U+0000 to U+007F range (i.e. US ASCII)
     * by re-encoding those characters into two character pairs and then using the normal
     * Code 39 barcode. The re-encoding algorithm is described on
     * <a target=_new href="http://www.barcodeman.com/info/c39_ext.php3">this page</a>.
     */
    public static final int BARCODE39X=4;

    /**
     * Barcode type for <code>drawBarCode</code> representing the "Extended Code 39" barcode,
     * with checksum. This barcode can display all the characters in the U+0000 to U+007F
     * range (i.e. US ASCII), by re-encoding those characters into two character pairs and then
     * using the normal Code 39 barcode. The re-encoding algorithm is described on
     * <a target=_new href="http://www.barcodeman.com/info/c39_ext.php3">this page</a>.
     */
    public static final int BARCODE39XCHECKSUM=5;

    /**
     * Barcode type for <code>drawBarCode</code> representing the "Code 128" barcode.
     * The Code 128 barcode can display digits, upper and lower-case letters and most
     * punctuation characters from the U+0020 - U+007E (US-ASCII) range. A checksum is
     * automatically included as part of the barcode. The appropriate varient
     * (CodeB or CodeC) is chosen automatically depending on the code that is printed.
     * EAN128 barcodes can also be printed by using a newline (<tt>\n</tt>) to represent
     * the FNC1 control character (this feature was added in version 1.1.23)
     */
    public static final int BARCODE128=6;

    /**
     * Barcode type for <code>drawBarCode</code> representing the EAN-13 barcode. An EAN-13
     * code represents a 13 digit number - broadly speaking, the first 7 digits the
     * country and manufacturer code, the next 5 digits the product code, and the final
     * digit the checksum. The 12 digit UPC-A barcodes as used in the USA are just EAN-13
     * codes with a leading zero. Most EAN-13 bar codes are an inch wide, so the recommended
     * <tt>width</tt>, as passed into the <code>drawBarCode</code> method, is 0.75.
     * @since 1.1.14
     */
    public static final int BARCODEEAN13=7;

    /**
     * Barcode type for <code>drawBarCode</code> representing the UPC-A barcode. Although
     * the Uniform Code Council in the US has declared that all UPC-A readers be able to
     * read EAN-13 codes by 2005, some clients may still prefer to use the older format
     * 12 digit UPC-A codes. Barcodes using this code type must be 11 digits long, or 12
     * digits if the check digit is pre-calculated. As with EAN-13, the recommended
     * <tt>width</tt> is 0.75
     * @since 1.2
     */
    public static final int BARCODEUPCA=9;

    /**
     * Barcode type for <code>drawBarCode</code> representing the "Codabar" barcode. A Codabar
     * code can contain the digits 0 to 9, plus the characters +, /, $, -, : and the decimal
     * point (.).  Additionally it must begin and end with a "stop letter", which may be one
     * of A, B, C or D.
     * @since 1.1.14
     */
    public static final int BARCODECODABAR=8;


    PDFPage(org.faceless.pdf2.PDFPage page)
    {
	this.page = page;
	state=new State();
	statestack = new Stack();
	setCanvas(0,0,page.getWidth(), page.getHeight(), POINTS, PAGEBOTTOM|PAGELEFT);
    }

    Object getPeer()
    {
        return page;
    }

    /**
     * Return the width of the page in points. This returns the width of the
     * visible page (as defined by the CropBox) as opposed to the width of
     * the physical page. For 99% of documents this is the same value.
     */
    public float getWidth()
    {
	return page.getWidth();
    }

    /**
     * Return the height of the page in points. This returns the height of the
     * visible page (as defined by the CropBox) as opposed to the height of
     * the physical page. For 99% of documents this is the same value.
     */
    public float getHeight()
    {
	return page.getHeight();
    }

    /**
     * Get which page this is in the PDF document - the first page is number 1.
     * @since 1.1
     */
    public int getPageNumber()
    {
	return page.getPageNumber();
    }

    /**
     * Set the current "canvas", or drawing area. When a new page is
     * created, the canvas defaults to the entire page, measured in points
     * from the bottom-left hand corner of the page. The canvas can be reset
     * as many times as necessary.
     *
     * @param left the left edge of the canvas, in points
     * @param bottom the bottom edge of the canvas, in points
     * @param width the width of the canvas, in points
     * @param height the height of the canvas, in points
     * @param scale the units to measure it in. Can be {@link #POINTS} (the default),
     * {@link #INCHES}, {@link #CM}, {@link #MM}, {@link #PICAS} or {@link #PERCENT}
     * @param zerocorner which corner of the page is nearest to (0,0). A logical-or
     * of {@link #PAGETOP}, {@link #PAGELEFT}, {@link #PAGERIGHT} and {@link #PAGEBOTTOM}
     *
     */
    public void setCanvas(float left, float bottom, float width, float height, int scale, int zerocorner)
    {
	float newscale=page.UNITS_POINTS;
	int neworigin=0;

	translatex=left;
	translatey=bottom;
	if (scale==POINTS)	scalex=scaley=page.UNITS_POINTS;
	else if (scale==INCHES) scalex=scaley=page.UNITS_INCHES;
	else if (scale==CM)	scalex=scaley=page.UNITS_CM;
	else if (scale==MM)	scalex=scaley=page.UNITS_MM;
	else if (scale==PICAS)	scalex=scaley=page.UNITS_PICAS;
	else if (scale==PERCENT) {
	    scaley=height/100;
	    scalex=width/100;
	}

	if ((zerocorner&PAGETOP)==PAGETOP)	{ scaley=-scaley; translatey+=height; }
	if ((zerocorner&PAGERIGHT)==PAGERIGHT)	{ scalex=-scalex; translatex+=width; }

	canvaswidth=width;
	canvasheight=height;
    }

    private final float cx(float x) 	 { return (translatex+x*scalex)*state.scalex + state.translatex; }
    private final float cy(float y) 	 { return (translatey+y*scaley)*state.scaley + state.translatey; }
    private final float canvasx(float x) { return translatex + x*scalex; }
    private final float canvasy(float y) { return translatey + y*scaley; }


    /**
     * Get the height of the current canvas in points.
     */
    public float getCanvasHeight()
    {
	return canvasheight;
    }

    /**
     * Get the width of the current canvas in points.
     */
    public float getCanvasWidth()
    {
	return canvaswidth;
    }

    /**
     * Set the current style.
     */
    public void setStyle(PDFStyle style)
    {
	page.setStyle(style.style);
	this.tempstyle=style;
    }

    /**
     * Return a copy of the the currently applied Style. Any changes to the
     * returned style won't take effect unless it's applied by calling
     * <code>setStyle</code>
     */
    public PDFStyle getStyle()
    {
	return (PDFStyle)PeeredObject.getPeer(page.getStyle());
    }

    /**
     * Draw a line from x1,y1 to x2,y2 in the current styles <code>LineColor</code>.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the start of the line
     * @param y1 the Y co-ordinate of the start of the line
     * @param x2 the X co-ordinate of the end of the line
     * @param y2 the Y co-ordinate of the end of the line
     * @throws IllegalStateException if the current style has no LineColor specified, or if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawLine(float x1, float y1, float x2, float y2)
    {
	page.drawLine(cx(x1),cy(y1),cx(x2),cy(y2));
    }

    /**
     * <p>
     * Draw a rectangle through the two corners (x1,y1) and
     * (x2,y2). Whether the rectangle is drawn as an outline
     * or filled depends on the <code>LineColor</code> and
     * <code>FillColor</code> of the current style (see the
     * {@link #pathPaint} method for more information).
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawRectangle(float x1, float y1, float x2, float y2)
    {
	page.drawRectangle(cx(x1),cy(y1),cx(x2),cy(y2));
    }

    /**
     * <p>
     * Draw a rectangle between the two corners (x1,y1) and
     * (x2,y2). The corners of the rectangle are rounded, the
     * radius of the corner arcs is specified by the parameter
     * <code>r</code>.
     * </p>
     * <p>
     * Whether the rectangle is drawn as an outline or filled depends
     * the current style (see the {@link #pathPaint} method for more
     * information).
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @param r The radius of the circle used to round the corners. A value
     * of zero produces an identical result to <code>drawRectangle</code>.
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     * @since 1.1
     */
    public void drawRoundedRectangle(float x1, float y1, float x2, float y2, float r)
    {
	page.drawRoundedRectangle(cx(x1),cy(y1),cx(x2),cy(y2),r);
    }


    /**
     * <p>
     * Draw a polygon. The X and Y co-ordinates of the vertices are
     * in the supplied arrays. Whether the polygon is drawn as an
     * outline or filled depends on the <code>LineColor</code> and
     * <code>FillColor</code> of the current style (see the
     * {@link #pathPaint} method for more information).
     * </p>
     * <p>
     * (The resulting shape isn't a true polygon, in that it doesn't
     * have to be closed, but we felt that <code>drawPolygon</code>
     * was catchier than <code>drawSequenceOfLineSegments</code>.)
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinates of the vertices
     * @param y the Y co-ordinates of the vertices
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawPolygon(float[] x, float[] y)
    {
	float[] x2 = new float[x.length];
	float[] y2 = new float[y.length];
	for (int i=0;i<x.length;i++) x2[i]=cx(x[i]);
	for (int i=0;i<y.length;i++) y2[i]=cy(y[i]);
	
	page.drawPolygon(x2, y2);
    }


    /**
     * <p>
     * Draw an ellipse inside the specified rectangle. To
     * draw a circle centered on 300,200 with a radius of
     * 50, the invocation would be
     * <code>drawEllipse(250,150,350,250)</code>. (<i>since
     * 1.1 this is a contrived example - it's easier to call
     * <code>drawCircle</code>)</i>
     * </p>
     * <p>
     * Whether the ellipse is drawn as an outline or filled depends on the
     * <code>LineColor</code> and <code>FillColor</code> of the current style
     * (see the {@link #pathPaint} method for more information).
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawEllipse(float x1, float y1, float x2, float y2)
    {
	page.drawEllipse(cx(x1), cy(y1), cx(x2), cy(y2));
    }


    /**
     * Draw a circle centered on <code>x</code>, <code>y</code>
     * with a radius of <code>r</code>. A more convenient way to
     * draw circles than with <code>drawEllipse</code>.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinate of the center of the circle
     * @param y the Y co-ordinate of the center of the circle
     * @param r the radius of the circle
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     * @since 1.1
     */
    public void drawCircle(float x, float y, float r)
    {
	page.drawEllipse(cx(x-r), cy(y-r), cx(x+r), cy(y+r));
    }

    /**
     * <p>
     * Draw an arc inside the specified rectangle. The same as
     * <code>drawEllipse</code>, but allows you to specify a start
     * and end angle, and the line is always drawn as an outline.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @param start the angle to start the arc, in degrees clockwise
     * (with zero at 12 o'clock)
     * @param end the angle to end the arc, in degrees
     * @since 1.1
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawEllipseArc(float x1, float y1, float x2, float y2, float start, float end)
    {
	page.drawEllipseArc(cx(x1),cy(y1),cx(x2),cy(y2),start,end);
    }

    /**
     * Draw an arc of the circle centered on
     * <code>x</code>, <code>y</code> with a radius
     * of <code>r</code>. A more convenient way to
     * draw circular arcs than <code>drawEllipseArc</code>.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinate of the center of the circle
     * @param y the Y co-ordinate of the center of the circle
     * @param start the angle to start the arc, in degrees clockwise
     * (with zero at 12 o'clock)
     * @param end the angle to end the arc, in degrees
     * @since 1.1
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void drawCircleArc(float x, float y, float r, float start, float end)
    {
	page.drawEllipseArc(cx(x-r),cy(y-r),cx(x+r),cy(y+r),start,end);
    }


    /**
     * Start a new path at the specified position. If a path has
     * already been started, move the cursor without drawing a line.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinate to move to
     * @param y the Y co-ordinate to move to
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathMove(float x, float y)
    {
	page.pathMove(cx(x),cy(y));
    }

    /**
     * Continue the path in a straight line to the specified point
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinate to move to
     * @param y the Y co-ordinate to move to
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathLine(float x, float y)
    {
	page.pathLine(cx(x),cy(y));
    }

    /**
     * Continue the path in a bezier curve to the specified point.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param cx1 the X co-ordinate of the first control point for the curve
     * @param cy1 the Y co-ordinate of the first control point for the curve
     * @param cx2 the X co-ordinate of the second control point for the curve
     * @param cy2 the Y co-ordinate of the second control point for the curve
     * @param x the X co-ordinate to move to
     * @param y the Y co-ordinate to move to
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathBezier(float cx1, float cy1, float cx2, float cy2, float x, float y)
    {
	page.pathBezier(cx(cx1),cy(cy1),cx(cx2),cy(cy2),cx(x),cy(y));
    }

    /**
     * Continue the path in an arc
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param width the width of the ellipse to take the arc from
     * @param height the height of the ellipse to take the arc from
     * @param start the angle to start the arc from, in degrees clockwise
     * @param end the angle to finish the arc on, in degrees clockwise
     * @since 1.1
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathArc(float width, float height, float start, float end)
    {
	page.pathArc(width,height,start,end);
    }

    /**
     * Close the path by drawing a straight line back to its beginning.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathClose()
    {
	page.pathClose();
    }

    /**
     * Cancel the current path.
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathCancel()
    {
	page.pathCancel();
    }

    /**
     * Paint the path. What this actually does depends on the currently
     * applied <code>PDFStyle</code>.
     * <ul>
     * <li>If the style has a LineColor specified but no FillColor, "stroke"
     * the path by drawing it as an outline in the current line color</li>
     * <li>If the style has a FillColor specified but no LineColor, call
     * {@link #pathClose} and "fill" the path with the current fill color</li>
     * <li>If the style has both a FillColor and a  LineColor, call {@link
     * #pathClose}, "fill" the path with the current fill color then "stroke"
     * the path with the current line color.</li>
     * </ul>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @throws IllegalStateException if neither a fill color or a line color
     * is specified.
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathPaint()
    {
	page.pathPaint();
    }

    /**
     * Allows the path to be painted and used to set the clipping area
     * in one operation. See the {@link #pathPaint} and {@link #pathClip}
     * methods for more information
     * @since 1.1.10
     */
    public void pathClipAndPaint()
    {
	page.pathClipAndPaint();
    }

    /**
     * <p>
     * Set the "clipping area" of the page to be the intersection of
     * the current clipping area and the shape defined by this path.
     * Any future graphics or text operations on the page are only
     * applied within this area.
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void pathClip()
    {
	page.pathClip();
    }

    /**
     * <p>
     * Identical to {@link #drawRectangle}, but instead of drawing this
     * method sets the clipping area to the specified rectangle
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void clipRectangle(float x1, float y1, float x2, float y2)
    {
	page.clipRectangle(cx(x1),cy(y1),cx(x2),cy(y2));
    }


    /**
     * <p>
     * Identical to {@link #drawRoundedRectangle}, but instead of drawing this
     * method sets the clipping area to the specified shape
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @param r The radius of the circle used to round the corners. A value
     * of zero produces an identical result to <code>clipRectangle</code>.
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void clipRoundedRectangle(float x1, float y1, float x2, float y2, float r)
    {
	page.clipRoundedRectangle(cx(x1),cy(y1),cx(x2),cy(y2),r);
    }

    /**
     * <p>
     * Identical to {@link #drawPolygon}, but instead of drawing this
     * method sets the clipping area to the specified shape.
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * </p>
     * @param x the X co-ordinates of the vertices
     * @param y the Y co-ordinates of the vertices
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void clipPolygon(float[] x, float[] y)
    {
	float[] x2 = new float[x.length];
	float[] y2 = new float[y.length];
	for (int i=0;i<x.length;i++) x2[i]=cx(x[i]);
	for (int i=0;i<y.length;i++) y2[i]=cy(y[i]);

	page.clipPolygon(x2,y2);
    }

    /**
     * <p>
     * Identical to {@link #drawEllipse}, but instead of drawing this
     * method sets the clipping area to the specified shape
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x1 the X co-ordinate of the first corner of the rectangle
     * @param y1 the Y co-ordinate of the first corner of the rectangle
     * @param x2 the X co-ordinate of the second corner of the rectangle
     * @param y2 the Y co-ordinate of the second corner of the rectangle
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void clipEllipse(float x1, float y1, float x2, float y2)
    {
	page.clipEllipse(cx(x1),cy(y1),cx(x2),cy(y2));
    }

    /**
     * <p>
     * Identical to {@link #drawCircle}, but instead of drawing this
     * method sets the clipping area to the specified shape
     * </p><p>
     * There is no way to enlarge the current clipping area, or to set
     * a new clipping area without reference to the current one. However,
     * as the current clipping area is part of the graphics state, it
     * can and should be nested inside calls to {@link #save} and
     * {@link #restore} to limit its effect.
     * </p>
     * <p>Calls to this method can't be made between calls to <tt>beginText</tt> and <tt>endText</tt>, as this violates the PDF specification. Since 1.1.6 An <tt>IllegalStateException</tt> will be thrown.
     * @param x the X co-ordinate of the center of the circle
     * @param y the Y co-ordinate of the center of the circle
     * @param r the radius of the circle
     * @since 1.1.5
     * @throws IllegalStateException if the call is nested between a call to <tt>beginText</tt> and <tt>endText</tt>
     */
    public void clipCircle(float x, float y, float r)
    {
	page.clipCircle(cx(x),cy(y),r);
    }

    /**
     * <p>
     * Save the state of this page. This takes a snapshot of the
     * currently applied style, position, clipping area and any
     * rotation/translation/scaling that has been applied, which can
     * be later restored with a call to {@link #restore} or undone
     * with a call to {@link #undo}.
     * </p><p>
     * Calls to <code>save</code> can be nested, but note that for
     * most PDF viewers it is an error to save the page state but
     * not restore it. The <tt>save()</tt> method now saves the
     * entire state of the style.
     * </p><p>
     * Since version 1.1, additional restrictions have been placed
     * on the <code>save</code> and <code>restore</code> methods.
     * <li>They can only be nested 28 deep</li>
     * <li>They cannot be called betweem a <code>pathMove</code>
     * and a <code>pathPaint</code> or <code>pathCancel</code> call, or
     * between <code>beginText</code> and <code>endText</code>. This
     * is because in PDF (unlike its parent PostScript), save does <i>not</i>
     * save path information.</li>
     * This ties in more accurately with the PDF specification.
     * </p>
     *
     * @throws IllegalStateException if a save is performed between a
     * call to <code>beginText</code> and <code>endText</code>, if there
     * is an open path, or if saves are nested more than 12 deep.
     */
    public void save()
    {
	page.save();
	statestack.push(state);
    }

    /**
     * <p>
     * Restore the state saved with the last call to {@link #save}.
     * </p>
     * @throws IllegalStateException if the state wasn't previously saved
     */
    public void restore()
    {
	page.restore();
	state = (State)statestack.pop();
    }

    /**
     * <p>
     * Undo the page to the state at the last call to <code>save()</code>
     * </p>
     * @throws IllegalStateException if the state wasn't previously saved
     * </p>
     * @since 1.1
     */
    public void undo()
    {
	throw new UnsupportedOperationException("The undo() method has been removed in version 2 with no replacement. You'll need to rewrite your code or stick with version 1");
    }


    /**
     * <p>
     * Rotate the page. All future actions, like drawing lines or text,
     * will be rotated around the specified point by the specified degrees.
     * </p>
     * @param x the X co-ordinate to rotate the page around
     * @param y the Y co-ordinate to rotate the page around
     * @param ang The number of degrees clockwise to rotate the page.
     */
    public void rotate(float x, float y, double ang)
    {
	page.rotate(cx(x),cy(y), ang);
    }

    /**
     * <p>
     * Translate the page by the specified amount.
     * All future actions, like drawing lines or text,
     * will be offset by the specified amount.
     * </p>
     * @param x the distance to translate the page in the X axis
     * @param y the distance to translate the page in the Y axis
     */
    public void translate(float x, float y)
    {
	state.translatex += x*state.scalex;
	state.translatey += y*state.scaley;
    }

    /**
     * <p>
     * Scale the page by the specified amount.
     * All future actions, like drawing lines or text,
     * will be scaled in both directions by the specified amounts.
     * </p>
     * @param x the scaling factor to apply in the X axis, with 1.0 being no change
     * @param y the scaling factor to apply in the Y axis, with 1.0 being no change
     */
    public void scale(float x, float y)
    {
	if (x*y==0) throw new IllegalArgumentException("X or Y is zero");
	state.scalex *= x;
	state.scaley *= y;
    }

    /**
     * <p>
     * Set the action to perform when this page is displayed. This
     * method is conceptually similar to the method with the same name in
     * the {@link PDF} object, except that whereas that is run once when the
     * document is opened, this is run each time the page is displayed.
     * </p>
     * @param action the action to run each time this page is displayed, or
     * <code>null</code> to clear the action
     * @since 1.1
     */
    public void setOpenAction(PDFAction action)
    {
	page.setAction(org.faceless.pdf2.Event.OPEN, action==null ? null : action.action);
    }

    /**
     * <p>
     * Set the action to perform when this page is closed. The opposite
     * of the <code>setOpenAction</code> method, this action will be
     * run each time the page is closed, either by closing the document
     * or by moving to another page.
     * </p>
     * @param action the action to run each time this page is closed, or
     * <code>null</code> to clear the action
     * @since 1.1
     */
    public void setCloseAction(PDFAction action)
    {
	page.setAction(org.faceless.pdf2.Event.CLOSE, action==null ? null : action.action);
    }

    /**
     * <p>
     * Get the action that's perform when this page is displayed. This is
     * the value set by the {@link #setOpenAction} method.
     * @return the action performed whenever this page is displayed, or <tt>null</tt>
     * if no action is performed.
     * @since 1.1.12
     */
    public PDFAction getOpenAction()
    {
	return (PDFAction)PeeredObject.getPeer(page.getAction(org.faceless.pdf2.Event.OPEN));
    }

    /**
     * <p>
     * Get the action that's perform when this page is displayed. This is
     * the value set by the {@link #setOpenAction} method.
     * @return the action performed whenever this page is displayed, or <tt>null</tt>
     * if no action is performed.
     * @since 1.1.12
     */
    public PDFAction getCloseAction()
    {
	return (PDFAction)PeeredObject.getPeer(page.getAction(org.faceless.pdf2.Event.CLOSE));
    }


    /**
     * <p>
     * Set the filter to be applied to this page. The default filter is set to
     * {@link #FILTER_FLATE}, but it can be set to {@link #FILTER_NONE}
     * to simplify debugging.
     * </p>
     * @param filter the filter to be applied to the page {@link PDFStream}
     */
    public void setFilter(int filter)
    {
    	// NOOP
    }

    /**
     * <p>
     * Add an annotation to the page.
     * </p>
     * @see PDFAnnotation
     * @since 1.1
     */
    public void addAnnotation(PDFAnnotation annotation)
    {
	page.getAnnotations().add(annotation.annot);
    }

    /**
     * Remove the specified annotation from the page. If
     * the annotation is not on this page, this method
     * has no effect
     * @since 1.1.23
     */
    public void removeAnnotation(PDFAnnotation annotation)
    {
	page.getAnnotations().remove(annotation.annot);
    }

    /**
     * Return a list of all the annotations on this page. If no
     * annotations exist, this returns a list of zero length.
     * @return the list of annotations on this page
     * @since 1.1.12
     */
    public PDFAnnotation[] getAnnotations()
    {
	List l = page.getAnnotations();
	PDFAnnotation[] z = new PDFAnnotation[l.size()];
	for (int i=0;i<z.length;i++) {
	    z[i]=(PDFAnnotation)PeeredObject.getPeer(l.get(i));
	}
	return z;
    }

    /**
     * <p>
     * Seek to the start of the page. Any items drawn after this call
     * will be drawn before any content already existing on the page, so
     * appearing under the current content.
     * </p><p>
     * This method will throw an <tt>IllegalStateException</tt> if called
     * while a path is open or between calls to <tt>beginText</tt> and
     * <tt>endText</tt>.
     * </p>
     * <p>
     * Note that if the document clears the page before writing, it will
     * overwrite any content written after a <tt>seetkStart</tt>
     * </p>
     * @since 1.1.12
     */
    public void seekStart()
    {
	page.seekStart();
    }

    /**
     * <p>
     * Seek to the end of the page. Any items drawn after this call
     * will be drawn after any content already existing on the page, so
     * appearing above the current content. This is the default.
     * </p><p>
     * This method will throw an <tt>IllegalStateException</tt> if called
     * while a path is open or between calls to <tt>beginText</tt> and
     * <tt>endText</tt>.
     * </p>
     * @since 1.1.12
     */
    public void seekEnd()
    {
	page.seekEnd();
    }


    /**
     * <p>
     * Draw a <code>PDFImage</code> on the page at the specified location. The
     * aspect-ratio of the image is dependent on the with and height of the
     * rectangle given here, <i>not</i> the width and height of the original
     * image. To avoid distorting the aspect ratio, the method can be called
     * like so:
     * <pre>drawImage(img, 100, 100, 100+img.getWidth(), 100+img.getHeight());</pre>
     * </p>
     *
     * @param image The image to draw
     * @param x1 the X co-ordinate of the first corner of the image
     * @param y1 the Y co-ordinate of the first corner of the image
     * @param x2 the X co-ordinate of the second corner of the image
     * @param y2 the Y co-ordinate of the second corner of the image
     *
     */
    public void drawImage(PDFImage image, float x1, float y1, float x2, float y2)
    {
	page.drawImage(image.image,cx(x1),cy(y1),cx(x2),cy(y2));
    }

    /**
     * <p>
     * Change the text in the supplied string to use the "correct" quote characters - i.e.
     * for English change "test" to ``test'', for German change it to ,,test`` and so on.
     * </p>
     * <p>
     * Exactly what substitution takes place depends on the current locale of the PDF
     * document. We've taken the definition of "correct" from the Unicode standard,
     * version 3.0 (in the event that either they or (more likely) us have got it wrong,
     * please let us know). The current implementation has rules for English, Dutch,
     * Italian, Spanish, Catalan, German, Portugese, Turkish, Polish, Hungarian, Swedish,
     * Finnish, Norwegian, Danish, Czech and Slovak. Languages using guillemets for
     * quotes (French, Greek, Russian and Slovenian) are not covered, as it's expected that
     * the guillemet characters will be used in place of the normal single (') and double
     * (") quote characters.
     * </p>
     * <p>
     * Please note the substitution will <i>only</i> take place if the current styles' font
     * has the required characters defined. The 14 standard fonts do, and most others
     * should.
     * </p>
     * <p>
     * Finally, the algorithm isn't perfect - it's more likely to work if spaces are placed
     * before opening quotes, and closing quotes are followed by a space or punctuation.
     * If it's still making mistakes, you can prevent a quote from being "turned" by
     * surrounding the character with U+200C (zero-width non-joiner) characters.
     * </p>
     * @param text the text to substitute
     * @return the passed in string with the appropriate quote characters for the Locale
     * in place of characters single quote (', 0x27) and double quote (", 0x22)
     * @since 1.1
     */
    public String requote(String text)
    {
	char[] c = text.toCharArray();
	// TODO - find proper locale
	PDFStyle style = getStyle();
        if (style!=null && style.getFont()!=null && style.getFont().requote(c,0,c.length, Locale.getDefault())) {
	    return new String(c,0,c.length);
	} else {
	    return text;
	}
    }

    /**
     * <p>
     * Draw a barcode at the specified position. The type of barcode
     * is specified by the <code>type</code> parameter, and may be
     * one of {@link #BARCODE39}, {@link #BARCODE39CHECKSUM},
     * {@link #BARCODE39X}, {@link #BARCODE39XCHECKSUM},
     * {@link #BARCODE25}, {@link #BARCODE25CHECKSUM},
     * {@link #BARCODE128}, {@link #BARCODEEAN13} or {@link #BARCODECODABAR}.
     * Each of these algorithms has restrictions on what characters
     * can be displayed, and an exception is thrown if an illegal
     * character is given.
     * </p><p>
     * The width of the resulting barcode in points is returned.
     * The height of the barcode is 15% of the width, with a
     * minimum height of 18 points. If text is displayed, you can
     * add another <code>(8*width)</code> points to the height.
     * </p><p>
     * @param type the type of barcode to print
     * @param code the string to print
     * @param x the left-most position of the barcode on the page
     * @param y the vertical center of the barcode on the page
     * @param showtext whether to show the human-readable equivalent
     * of the barcode immediately beneath the code
     * @param width the width of the thinnest bar in points. Acceptable
     * values depend on your scanner. The recommended minimum is 0.54
     * points, or 0.0075 inches (0.19mm). If in doubt, use "1".
     * @return the width of the resulting barcode, in points
     * @throws IllegalArgumentException if the characters or the barcode
     * type is invalid
     * @since 1.1.5
     */
    public float drawBarCode(int type, String code, float x, float y, boolean showtext, float width)
        throws IllegalArgumentException
    {
        return drawBarCode(type, code, cx(x), cy(y), showtext, width, 18, 2.8f);
    }

    /**
     * <p>
     * Draw a barcode at the specified position. Identical to the other
     * barcode routine, but allows two extra properties to be specified
     * for full control over the resulting code - the <code>height</code>,
     * which is the height of the barcode in points, and the <code>ratio</code>,
     * which is the thickbar/thinbar ratio for those codes that only use
     * two bar widths (CODE39 and CODE25).
     * </p><p>
     * The specified height will always be rounded up to 18 points or 15% of the
     * width of the barcode, whichever is greater.
     * </p><p>
     * The ratio should always be 2.0 and 3.0 - the default is 2.8. For most
     * algorithms, if the thinnest bar has a width of less than 1.5 points
     * then the ratio should be between 2.0 and 2.2.
     * </p>
     * @param type the type of barcode to print
     * @param code the string to print
     * @param x the left-most position of the barcode on the page
     * @param y the vertical center of the barcode on the page
     * @param showtext whether to show the human-readable equivalent
     * of the barcode immediately beneath the code
     * @param width the width of the thinnest bar in points. Acceptable
     * values depend on your scanner. The recommended minimum is 0.54
     * points, or 0.0075 inches (0.19mm). If in doubt, use "1"
     * @param height the height of the barcode in points. Minimum value is 18
     * @param ratio the ratio of the thickest bar in the barcode to the thinnest,
     * if applicable. Valid values are between 2.0 and 3.0. For multiple-width
     * codes like Code128, this is ignored. If in doubt, try "2.8"
     * @return the width of the resulting barcode, in points
     * @throws IllegalArgumentException if the characters or the barcode
     * type is invalid
     * @since 1.1.13
     */
    public float drawBarCode(int type, String code, float x, float y, boolean showtext, float width, int height, float ratio)
        throws IllegalArgumentException
    {
	int newtype;
	if (type==BARCODE39) newtype=org.faceless.pdf2.BarCode.CODE39;
	else if (type==BARCODE39CHECKSUM) newtype=org.faceless.pdf2.BarCode.CODE39_CHECKSUM;
	else if (type==BARCODE39X) newtype=org.faceless.pdf2.BarCode.CODE39X;
	else if (type==BARCODE39XCHECKSUM) newtype=org.faceless.pdf2.BarCode.CODE39X_CHECKSUM;
	else if (type==BARCODE25) newtype=org.faceless.pdf2.BarCode.INTERLEAVED25;
	else if (type==BARCODE25CHECKSUM) newtype=org.faceless.pdf2.BarCode.INTERLEAVED25_CHECKSUM;
	else if (type==BARCODE128) newtype=org.faceless.pdf2.BarCode.CODE128;
	else if (type==BARCODEEAN13) newtype=org.faceless.pdf2.BarCode.EAN13;
	else if (type==BARCODEUPCA) newtype=org.faceless.pdf2.BarCode.UPCA;
	else if (type==BARCODECODABAR) newtype=org.faceless.pdf2.BarCode.CODABAR;
	else throw new IllegalArgumentException("Unknown barcode type");

	org.faceless.pdf2.BarCode codeo = new org.faceless.pdf2.BarCode(type, code);
	codeo.setShowText(showtext);
	codeo.setBarWidth(width);
	codeo.setHeight(height);
	codeo.setBarRatio(ratio);

	float barwidth=codeo.getWidth();
	float fontheight = (showtext ? width*8 : 0)*1.25f;
	float barheight=height+fontheight;

	page.drawBarCode(codeo, cx(x), cy(y)+(barheight/2)-(fontheight/2), cx(x)+barwidth, cy(y)-(barheight/2)-(fontheight/2));
	return barwidth;
    }

    /**
     * Set the XML metadata associated with this object. See
     * {@link PDF#setMetaData} for more information.
     * @param xmldata the XML data to embed into the document, or <tt>null</tt> to clear any existing metadata. No validation is performed on this input.
     * @since 1.1.12
     */
    public void setMetaData(String xmldata)
    {
	page.setMetaData(xmldata);
    }

    /**
     * Return any XML metadata associated with this object. See the
     * {@link PDF#getMetaData} for more information
     * @return a {@link java.io.Reader} containing the source of the XML or <tt>null</tt> if no metadata is available.
     * @throws IOException if the metadata can't be extracted
     * @since 1.1.12
     */
    public Reader getMetaData()
        throws IOException
    {
	return page.getMetaData();
    }

    /**
     * <p>
     * Add the contents of the specified page to this page, at the specified
     * position. The page to be added is treated in a similar way to an image
     * in the {@link #drawImage} method - it's scaled to fit the specified
     * rectangle, but it's up to the user to preserve the original aspect ratio.
     * </p><p>
     * It is anticipated that this method will be used with the {@link PDFReader}
     * class to allow pages to stitched together, overlaid, changed from
     * Letter to A4 and so on.
     * </p>
     * <p>
     * Here's an example showing two pages being placed next to eachother in a
     * "2-up" layout.
     * </p>
     * <pre>
     *   void drawTwoUp(PDFPage page1, PDFPage page2, PDFPage dest)
     *   {
     *       dest.setCanvas(0,0,dest.getWidth(),dest.getHeight(), PDFPage.PERCENT, PDFPage.PAGETOP);
     *       dest.drawPage(page1, 0, 0, 50, 100);	// from (0%,0%) to (50%,100%)
     *       dest.drawPage(page2, 50, 0, 100, 100);	// from (50%,0%) to (100%,100%)
     *   }
     * </pre>
     * <b>Note</b>. For simply copying pages from one document to another, it's
     * <i>considerably</i> faster, and easier, to join the two pages together by
     * manipulating the list of pages returned from {@link PDF#getPages}.
     *
     * @param page The page whose contents are to be drawn onto this page
     * @param x1 the X co-ordinate of the first corner of the image
     * @param y1 the Y co-ordinate of the first corner of the image
     * @param x2 the X co-ordinate of the second corner of the image
     * @param y2 the Y co-ordinate of the second corner of the image
     *
     * @since 1.1.12
     */
    public void drawPage(PDFPage page, float x1, float y1, float x2, float y2)
    {
	org.faceless.pdf2.PDFCanvas canvas = new org.faceless.pdf2.PDFCanvas(page.page);
	this.page.drawCanvas(canvas, cx(x1), cy(y1), cx(x2), cy(y2));

	if (page.page.getAnnotations().size()>0) {
	    org.faceless.pdf2.PDFPage clone = new org.faceless.pdf2.PDFPage(page.page);

	    x1 = canvasx(x1);
	    y1 = canvasy(y1);
	    x2 = canvasx(x2);
	    y2 = canvasy(y2);
	    if (x1>x2) { float t=x1; x1=x2; x2=t; }
	    if (y1>y2) { float t=y1; y1=y2; y2=t; }

//	    System.err.println("clone="+clone);
	    List annots = clone.getAnnotations();
	    for (int i=0;i<annots.size();i++) {
		org.faceless.pdf2.PDFAnnotation annot = (org.faceless.pdf2.PDFAnnotation)annots.get(i);
		float[] f = annot.getRectangle();
		if (f!=null) {
//		    System.err.println("page="+page.getWidth()+"x"+page.getHeight()+" x1="+x1+" y1="+y1+" x2="+x2+" y2="+y2);
//		    System.err.println("WAS F="+f[0]+","+f[1]+"-"+f[2]+","+f[3]);
		    f[0] = (f[0]/clone.getWidth()*(x2-x1))+x1;
		    f[1] = (f[1]/clone.getHeight()*(y2-y1))+y1;
		    f[2] = (f[2]/clone.getWidth()*(x2-x1))+x1;
		    f[3] = (f[3]/clone.getHeight()*(y2-y1))+y1;

		    annot.setRectangle(f[0], f[1], f[2], f[3]);
//		    System.err.println("NOW F="+f[0]+","+f[1]+"-"+f[2]+","+f[3]);
		}
		this.page.getAnnotations().add(annot);
	    }
	}
    }

    /**
     * <p>
     * Draw a line of text at the specified position. A simple way to draw
     * a single line of text. The co-ordinates specify the position of the
     * baseline of the first character - for other positions (e.g. to align
     * the top of the text), adjust the co-ordinates by the return value from
     * {@link PDFStyle#getTextTop} and friends.
     * </p>
     * @param text the line of text to draw
     * @param x the X co-ordinate to draw the text at
     * @param y the Y co-ordinate to draw the text at
     */
    public void drawText(String text, float x, float y)
    {
	page.drawText(text,cx(x),cy(y));
    }

    /**
     * <p>
     * Draw a line of text at a the specified position, and set it to
     * link to the specified action. A shorthand combination of
     * <code>drawText</code> and <code>beginTextLink</code>.
     * </p><p>
     * <i>Note that this method will not work as advertised if the position
     * of the text has been modified via the <code>rotate</code>, <code>scale</code>
     * or <code>translate</code> methods. This is a shortcoming inherent in
     * the PDF document specification</i>. See the {@link PDFAnnotation} class
     * documentation for more information.
     * </p>
     * @param text the line of text to draw
     * @param x the X co-ordinate to draw the text at
     * @param y the Y co-ordinate to draw the text at
     * @param action the action to perform when the text is clicked on
     * @since 1.1
     */
    public void drawTextLink(String text, float x, float y, PDFAction action)
    {
	page.drawTextLink(text,cx(x),cy(y),action.action);
    }

    /**
     * <p>
     * Begin a paragraph of text. The parameters specify the rectangle
     * measured in the current canvas units that will fully contain the text.
     * Left-to-right text will wrap when it reaches the right margin and
     * continue being rendered until the bottom margin is reached, after which
     * the text will not be rendered and all calls to <code>drawText</code>
     * will return -1. This "overflowed" text can be rendered in a new block
     * by calling <code>continueText</code>
     * </p>
     * <p><b>Note:</b> The <code>beginText</code>/<code>drawText</code>/<code>endText</code>
     * methods date from the 1.0 release of the PDF library, and while they
     * are suitable for simple text layout, more complex layout is best done
     * with the {@link LayoutBox} class. In particular these methods have issues
     * with the height calculations of text, and with what to do when the box
     * defined by <code>beginText</code> is full.
     * </p>
     *
     * @see LayoutBox
     * @param x1 the X co-ordinate of the first corner of the text rectangle.
     * @param y1 the Y co-ordinate of the first corner of the text rectangle.
     * @param x2 the X co-ordinate of the second corner of the text rectangle.
     * @param y2 the Y co-ordinate of the second corner of the text rectangle.
     * @throws IllegalStateException if beginText has already been called
     * (<code>beginText-endText</code> pairs can't be nested).
     */
    public void beginText(float x1, float y1, float x2, float y2)
    {
	page.beginText(cx(x1),cy(y1),cx(x2),cy(y2));
    }

    /**
     * <p>
     * As for beginText, but continue any text that overflowed from the
     * specified page. If the page being continued does not have an
     * unclosed <code>beginText</code> call, this method is identical
     * to calling <code>beginText</code> on the current page.
     * </p><p>
     * Since 1.1, this method automatically determines whether the new
     * text block should have any leading blank lines trimmed, or whether
     * the new block is contiguous with the old one.
     * </p>
     * <p><b>Note:</b> The <code>beginText</code>/<code>drawText</code>/<code>endText</code>
     * methods date from the 1.0 release of the PDF library, and while they
     * are suitable for simple text layout, more complex layout is best done
     * with the {@link LayoutBox} class. In particular these methods have issues
     * with the height calculations of text, and with what to do when the box
     * defined by <code>beginText</code> is full.
     * </p>
     * @see LayoutBox
     * @param x1 the X co-ordinate of the first corner of the text rectangle
     * @param y1 the Y co-ordinate of the first corner of the text rectangle
     * @param x2 the X co-ordinate of the second corner of the text rectangle
     * @param y2 the Y co-ordinate of the second corner of the text rectangle
     * @param page the page to take the overflowed text from
     */
    public float continueText(float x1, float y1, float x2, float y2, PDFPage page)
    {
	return this.page.continueText(cx(x1),cy(y1),cx(x2),cy(y2),page.page);
    }

    /**
     * <p>
     * End the paragraph of text
     * </p>
     * <p><b>Note:</b> The <code>beginText</code>/<code>drawText</code>/<code>endText</code>
     * methods date from the 1.0 release of the PDF library, and while they
     * are suitable for simple text layout, more complex layout is best done
     * with the {@link LayoutBox} class. In particular these methods have issues
     * with the height calculations of text, and with what to do when the box
     * defined by <code>beginText</code> is full.
     * </p>
     *
     * @param justifylast if the current text style is justified, whether to justify
     * the last line of text. If the current style is not justified, this has no effect.
     * @return the number of points that needed to be rendered to clear the buffer
     * @throws IllegalStateException if beginText wasn't called first
     */
    public float endText(boolean justifylast)
    {
	return page.endText(justifylast);
    }

    /**
     * Discard the paragraph of text. This method is identical to <code>endText</code>
     * in every way, except no text is actually rendered. This method is useful for
     * determining the size of a block of text without displaying it.
     * @since 1.0.1
     * @return the number of points that would have been rendered to clear the buffer
     */
    public float discardText()
    {
	return page.discardText();
    }

    /**
     * <p>
     * Draw a paragraph of text in the current styles font, size and color.
     * The text is automatically wrapped at the edge of the box specified in
     * the call to <code>beginText</code>, and is aligned according to the
     * alignment of the current style.
     * </p><p>
     * If any characters in the string aren't available in the current font,
     * they are ignored and a warning message is printed to
     * <code>System.err</code>.
     * </p><p>
     * This method returns -1 if the text can't be displayed in the
     * box specified by <code>beginText</code>.
     * </p><p>
     * The text to be drawn may contain newline characters, which have the
     * predictable effect.
     * </p>
     * <p><b>Note:</b> The <code>beginText</code>/<code>drawText</code>/<code>endText</code>
     * methods date from the 1.0 release of the PDF library, and while they
     * are suitable for simple text layout, more complex layout is best done
     * with the {@link LayoutBox} class. In particular these methods have issues
     * with the height calculations of text, and with what to do when the box
     * defined by <code>beginText</code> is full.
     * </p>
     *
     * @param text the line of text to be drawn
     * @throws IllegalStateException if no font or color is specified,
     * or if <code>beginText</code> hasn't been called first.
     * @return the number of points required to render the lines to
     * the document (zero or more), or -1 if the text box is full.
     * @see LayoutBox
     * @see PDFEncoding
     * @see PDFFont
     */
    public float drawText(String text)
    {
	return page.drawText(text);
    }

    /**
     * <p>
     * Start a "link" section in the text. Any text displayed between here
     * and the corresponding {@link #endTextLink} method call will act
     * as a <code>link</code> annotation, in the same way as the &lt;A&gt;
     * tag does in HTML: When the user clicks on the text, the specified
     * action is performed.
     * </p><p>
     * <i>Note that this method will not work as advertised if the position
     * of the text has been modified via the <code>rotate</code>, <code>scale</code>
     * or <code>translate</code> methods. This is a shortcoming inherent in
     * the PDF document specification</i>. See {@link PDFAnnotation#link} for
     * more information.
     * </p>
     * @param action the action to perform when the text is clicked on
     * @param linkstyle the style to apply to any text within the link area,
     * or <code>null</code> if the current style is to be used. For an underlined
     * link, use {@link PDFStyle#LINKSTYLE}
     * @throws IllegalStateException if a link has already been begun (links
     * can't be nested)
     * @see PDFAnnotation
     * @see PDFStyle#LINKSTYLE
     * @since 1.1
     */
    public void beginTextLink(PDFAction action, PDFStyle linkstyle)
    {
	page.beginTextLink(action.action, linkstyle.style);
    }

    /**
     * <p>
     * End the "link" section in the text, analogous to the &lt;/A&gt; tag
     * in HTML.
     * </p>
     * <p>
     * This method returns the list of annotations that were added - it's a
     * list because if the link wrapped over several lines or pages, several
     * annotations would have been added. The idea behind this is that you
     * can add annotations to the text, and then set the actions they refer
     * to (via the {@link PDFAnnotation#setAction} method) <i>after</i>
     * they've been added - for example, to link to a page that hasn't been
     * created yet.
     * </p>
     * @throws IllegalStateException if a link has not been begun
     * @since 1.1
     */
    public PDFAnnotation[] endTextLink()
    {
	org.faceless.pdf2.PDFAnnotation[] newannots = page.endTextLink();
	PDFAnnotation[] oldannots = new PDFAnnotation[newannots.length];
	for (int i=0;i<newannots.length;i++) {
	    oldannots[i]=(PDFAnnotation)PeeredObject.getPeer(newannots[i]);
	}
	return oldannots;
    }

    /**
     * Draw a LayoutBox at the specified position on the page.
     * @param box the LayoutBox to draw
     * @param x the X co-ordinate of the left hand side of the LayoutBox
     * @param y the Y co-ordinate of the top of the LayoutBox
     */
    public void drawLayoutBox(LayoutBox box, float x, float y)
    {
	page.drawLayoutBox(box.box,cx(x),cy(y));
    }

    public String toString()
    {
        return "{Page #"+getPageNumber()+"}";
    }
}
