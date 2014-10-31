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

	/* gameMap contains the plan of the sweets to collect initialized to
	 * null by default */
	static Circle[][] gameMap = new Circle[gridSize][gridSize]; 

	public ExampleDisplay(){
		super();
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setResizable(false);
		setLocation(30, 30);
		myContainer = getContentPane();
		myContainer.setPreferredSize(new Dimension(cellSize * (gridSize + 1), cellSize * (gridSize + 1) ));
		pack();

		// adding the red circles for a bit of landscape
//		Random rand = new Random();
//
//		for(int i = 0; i < numberOfSweets; i++) {
//			int j, k;
//			do {
//				j = rand.nextInt(gridSize);
//				k = rand.nextInt(gridSize);
//			} while (gameMap[j][k]!=null);
//
//			gameMap[j][k] = new Circle(this);
//			gameMap[j][k].setGridPos(j,k);
//		} // EndFor i

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
		System.out.println("KeyCode "+keyCode);
		if (!moveTable.containsKey(keyCode)) return ;
		int[] test = moveTable.get(keyCode);
		int[] newtest = {0, 0};
		Point newpoint = rect1.getLocation();
		newtest[0] = test[0] + newpoint.x;
		newtest[1] = test[1] + newpoint.y;
		System.out.println("newpoint"+newtest[0] +" "+newtest[1]);
		String send = newtest[0]+","+newtest[1];
//		String recv = "";
		try{
			send_socket(send);
//			System.out.println("Recv "+recv);
		}catch(IOException io){
			System.out.println("Exeption "+io);;
		}
//		System.out.println("Recv "+recv);
//		if(recv == "ok")
//			System.out.println("passe");
//			myRectangle.moveRect(test);
//		System.out.println("Map "+test[1]+ "map"+test[0]);
//		if (gameMap[rect1.x][rect1.y]!=null) {
//			pack();
//			numberOfSweets--;
//			if (numberOfSweets==0) {
//				System.out.println("You've won. Congratulations!");
//				System.exit(0);
//			}
//			System.out.println("Only "+numberOfSweets+" sweet(s) remaining...");
//		}
		repaint();
	} // EndMethod keyPressed

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
		ExampleDisplay window = new ExampleDisplay();
		// Fonction receive et fonction put triangle et fonction send4
		//    Receive = receive();    		
		String test = receive_ok();
		test = receive_ok();
		System.out.println("Add rectangle "+test);		    
		rect1 = add_rectangle(test, window);
		test = receive_ok();
//		System.out.println("Add player 2 "+test);
		rect2 = add_rectangle(test, window);
		test = receive_ok();
		add_cercle(test, window);
		new Thread() {
		      @Override
		      public void run() {
		    	  String position="";
		        while(true) { // This thread runs forever
		        	try{
		        	position = receive();
//		    		System.out.println("Receive thread "+position);
		        	}catch(IOException io){
		    			position="ko";
		    		}
		      }
		    }
		}.start();
//		if(test == "2")
//	    {
//	    	test = receive();
//	    	System.out.println("passe "+test);
//	    }
		//    }
		System.out.println("Fini ");
	} // EndMethod main

	public static Rectangle add_rectangle(String place, ExampleDisplay window)
	{

		String[] coord = place.split(",");
//		System.out.println("Coord "+coord[1]);
		int[] test = {Integer.parseInt(coord[0]), Integer.parseInt(coord[1])};
//		System.out.println("Place "+place);
		Rectangle myRectangle = new Rectangle(window) ;
		myRectangle.moveRect(test);
		myRectangle.repaint();
		return myRectangle;
	}

	public static String receive() throws IOException
	{
//		String newSt ="";
		String userInput = in.readLine();
		//	  String newString = userInput.substring(userInput.length());
//		System.out.println("Receive "+ userInput);
		String[] tab_S = userInput.split(";");
		System.out.println("String receive"+tab_S[0]+" "+tab_S[1]);
		if(tab_S[0].equals("1") )
		{
			System.out.println("triangle 1");
			move_rectangle1(tab_S[1]);
		}else if(tab_S[0].equals("2"))
		{
			System.out.println("triangle 2");
			move_rectangle2(tab_S[1]);
		}else if(tab_S[0].equals("3"))
		{
			remove_circle(tab_S[1]);
		}else
		{
			System.exit(0);;
		}
//			  while ((userInput = in.readLine()) != "ok\n") {
//			        System.out.println("echo: " + in.readLine());
//			    }
		return userInput;
	}
	
	public static String receive_ok() throws IOException
	{
		String userInput = in.readLine();
		//	  String newString = userInput.substring(userInput.length());
		System.out.println("Receive "+ userInput);
//			  while ((userInput = in.readLine()) != "ok\n") {
//			        System.out.println("echo: " + in.readLine());
//			    }
		return userInput;
	}

	
	public static void send_socket(String send) throws IOException
	{
		bufOut.write( send );
		bufOut.flush();
//		String userInput = receive_ok();
//		return userInput;
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
//		setVisible(true);
	}
	
	public static void remove_circle(String pos)
	{
		String[] npos = pos.split(",");
		int[] newpos = {Integer.parseInt(npos[0]), Integer.parseInt(npos[1])};
		Circle c = gameMap[newpos[0]][newpos[1]];
		myContainer.remove(c);
//		pack();
		gameMap[newpos[0]][newpos[1]]=null;
	}
} // EndClass ExampleDisplay
