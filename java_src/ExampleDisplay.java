// -*- compile-command: "javac ExampleDisplay.java" -*- 

/* FT14Oct13
 *
 * A very basic example of key-driven movement in Java. Repaint not
 * optimized. Note there is no separation between interface and logic
 * (MVC pattern, etc.)
 */

import java.io.*;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketAddress;

import java.util.Map ;
import java.util.HashMap ;
import java.util.List ;
import java.util.ArrayList ;

import java.util.Random ;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Container;
import java.awt.Point;
import java.awt.event.*; 

import javax.swing.JComponent;
import javax.swing.JFrame;

abstract class AbstractGridShape extends JComponent {

	/* Position of the shape in the grid */
	public int x = 0 ;
	public int y = 0 ;
	private ExampleDisplay dis ;

	public AbstractGridShape(ExampleDisplay display) {
		dis = display ;
		dis.add(this);
		dis.pack(); // somehow needed or add does not work properly
	}

	/*
	 * Set the positions of the shape in grid coordinates
	 */
	public void setGridPos(int someX,int someY) {
		x = someX ; y = someY ;
	}

	abstract public void drawShape(Graphics g,int x,int y,int w,int h);

	/* delegates drawing proper to drawShape. Transform the grid
	 * coordinates of the shape into pixel coordinates, using the cell
	 * size of the ExampleDisplay associated with the AbstractGridShape */
	public void paint(Graphics g) {
		this.drawShape(g,
				dis.cellSize/2 + x*dis.cellSize, 
				dis.cellSize/2 + y*dis.cellSize, 
				dis.cellSize, dis.cellSize);
	}

	public void moveRect(int[] delta) {
		x = (x+delta[0]+dis.gridSize)%dis.gridSize ;
		y = (y+delta[1]+dis.gridSize)%dis.gridSize ;
	}
} // EndClass AbstractGridShape

class Rectangle extends AbstractGridShape {
	public Rectangle(ExampleDisplay display) {
		super(display);
	}
	public void drawShape(Graphics g,int x,int y,int w,int h) {
		g.setColor(Color.BLUE);
		g.fillRect(x,y,w,h);
	}
} // EndClass Rectangle

class Circle extends AbstractGridShape {
	public Circle(ExampleDisplay display) {
		super(display);
	}
	public void drawShape(Graphics g,int x,int y,int w,int h) {
		g.setColor(Color.RED);
		g.fillOval(x,y,w,h);
	}
} // EndClass Circle

//Mettre tt la plus simple
public class ExampleDisplay extends JFrame implements KeyListener {
	static int cellSize = 20 ;
	static int gridSize = 20 ;
	Map<Integer,int[]> moveTable = new HashMap<Integer,int[]>() ;
//	static Rectangle myRectangle = null ;
	static Container myContainer ;
	int numberOfSweets = 10 ;
	static BufferedReader in = null;
	static Socket socket = null;
	static BufferedWriter bufOut = null;
	static Rectangle rect1 = null ;
	static Rectangle rect2 = null ;
	static ExampleDisplay window = null;

	/* gameMap contains the plan of the sweets to collect initialized to
	 * null by default */
	static Circle[][] gameMap = null; 

	public ExampleDisplay(){
		super();
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setResizable(false);
		setLocation(30, 30);
		myContainer = getContentPane();
		myContainer.setPreferredSize(new Dimension(cellSize * (gridSize + 1), cellSize * (gridSize + 1) ));
		pack();
		setVisible(true);
		moveTable.put(KeyEvent.VK_DOWN ,new int[] { 0,+1});
		moveTable.put(KeyEvent.VK_UP   ,new int[] { 0,-1});
		moveTable.put(KeyEvent.VK_LEFT ,new int[] {-1, 0});
		moveTable.put(KeyEvent.VK_RIGHT,new int[] {+1, 0});
		addKeyListener(this);

	} // EndConstructor ExampleDisplay

	/* needed to implement KeyListener */
	public void keyTyped   (KeyEvent ke){}
	public void keyReleased(KeyEvent ke){}

	/* where the real work happens: reacting to key being pressed */
	public void keyPressed (KeyEvent ke){ 
		int keyCode = ke.getKeyCode();
		if (!moveTable.containsKey(keyCode)) return ;
		int[] test = moveTable.get(keyCode);
		int[] newtest = {0, 0};
		Point newpoint = rect1.getLocation();
		newtest[0] = test[0] + newpoint.x;
		newtest[1] = test[1] + newpoint.y;
//		System.out.println("newpoint"+newtest[0] +" "+newtest[1]);
		String send = newtest[0]+","+newtest[1];
		try{
			send_socket(send);
//			System.out.println("Recv "+recv);
		}catch(IOException io){
			System.out.println("Exeption "+io);;
		}
		repaint();
	} // EndMethod keyPressed
	// Changer localhost
	public static void main(String[] a) throws IOException {
		 socket= new Socket();
		InetSocketAddress inetSocketAddress = new InetSocketAddress(InetAddress.getByName("localhost"), 5678);
		socket.connect(inetSocketAddress);
		PrintWriter out =
				new PrintWriter(socket.getOutputStream(), true);
		 bufOut = new BufferedWriter( new OutputStreamWriter( socket.getOutputStream() ) );
		bufOut.write( "ok" );
		bufOut.flush();
		in =	
				new BufferedReader(
						new InputStreamReader(socket.getInputStream()));
		
		// Fonction receive et fonction put triangle et fonction send4  		
		window = new ExampleDisplay();
		gameMap = new Circle[gridSize][gridSize];
		new Thread() {
		      @Override
		      public void run() {
		    	  String position="";
		        while(true) { // This thread runs forever
		        	try{
		        	position = receive();
		        	}catch(IOException io){
		    			position="ko";
		    		}
		      }
		    }
		}.start();
		
		System.out.println("Fini ");
	} // EndMethod main

	public static Rectangle add_rectangle(String place, ExampleDisplay window)
	{
		System.out.println("Add Rect "+ place);
		String[] coord = place.split(",");
		int[] test = {Integer.parseInt(coord[0]), Integer.parseInt(coord[1])};
		Rectangle myRectangle = new Rectangle(window) ;
		myRectangle.moveRect(test);
		myRectangle.repaint();
		return myRectangle;
	}

	public static String receive() throws IOException
	{
		String userInput = in.readLine();
		if(userInput.contains(";"))
		{
			String[] tab_S = userInput.split(";");
			if(tab_S[0].equals("1") )
			{
				move_rectangle1(tab_S[1]);
			}else if(tab_S[0].equals("2"))
			{
				move_rectangle2(tab_S[1]);
			}else if(tab_S[0].equals("3"))
			{
				remove_circle(tab_S[1], tab_S[2], tab_S[3]);
			}else if(tab_S[0].equals("5"))
			{
				rect1 = add_rectangle(tab_S[1], window);
			}else if(tab_S[0].equals("6"))
			{
				rect2 = add_rectangle(tab_S[1], window);
			}else if(tab_S[0].equals("4"))
			{
				if(tab_S[1].equals("other"))
				{
					System.out.println("You loose");
				}else if(tab_S[1].equals("equals"))
				{
					System.out.println("Equality");
				}else{
					System.out.println("You win");
				}
				send_socket("newgame");
				window.dispose();
				window = new ExampleDisplay();
				gameMap = new Circle[gridSize][gridSize];
	//			System.exit(0);
			}
			else if(tab_S[0].equals("7"))
			{
				String newstring = userInput.substring(2);
//				System.out.println("Substring "+newstring);
				add_cercle(newstring, window);
			}
		}
		return userInput;
	}
	
	public static String receive_ok() throws IOException
	{
		String userInput = in.readLine();
		System.out.println("Receive ok"+userInput);
		return userInput;
	}

	
	public static void send_socket(String send) throws IOException
	{
		bufOut.write( send );
		bufOut.flush();
	}
	
	public static void move_rectangle1(String pos)
	{
		String[] npos = pos.split(",");
		int[] newpos = {Integer.parseInt(npos[0]), Integer.parseInt(npos[1])};
		rect1.moveRect(newpos);
		rect1.repaint();
	}
	
	public static void move_rectangle2(String pos)
	{
		String[] npos = pos.split(",");
		int[] newpos = {Integer.parseInt(npos[0]), Integer.parseInt(npos[1])};
		rect2.moveRect(newpos);
		rect2.repaint();
	}
	
	public static void add_cercle(String point, ExampleDisplay window)
	{
		String[] npoint = point.split(";");
		System.out.println("Add Cercle "+ point);
		for(int i=0; i<npoint.length; i++)
		{
			String[] coord = npoint[i].split(",");
			int j = Integer.parseInt(coord[0]);
			int k = Integer.parseInt(coord[1]);
			gameMap[j][k] = new Circle(window);
			gameMap[j][k].setGridPos(j,k);
		}
	}
	
	public static void remove_circle(String pos, String score, String player)
	{
		String[] npos = pos.split(",");
		int[] newpos = {Integer.parseInt(npos[0]), Integer.parseInt(npos[1])};
		Circle c = gameMap[newpos[0]][newpos[1]];
		myContainer.remove(c);
		System.out.println("Score player "+ player +": "+ score);
		gameMap[newpos[0]][newpos[1]]=null;
	}
//	public static void start_game() throws IOException {
//		window = new ExampleDisplay();
//		String test = receive_ok();
//		test = receive_ok();	    
//		rect1 = add_rectangle(test, window);
//		test = receive_ok();
//		rect2 = add_rectangle(test, window);
//		test = receive_ok();
//		gameMap = new Circle[gridSize][gridSize];
//		add_cercle(test, window);
//		thread = new_thread();
//		thread.start();
//	}
} // EndClass ExampleDisplay
