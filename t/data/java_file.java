import java.io.*;
import java.util.*;

/**
 * Implement a greeting in Java
 *
 * @author	Thomas R. Wyant, III F<wyant at cpan dot org>
 * @version	0.000_001
 */

public class java_file {

    /**
     * This method is the mainline. It prints a greeting to the name
     * given as the first command-line argument, defaulting to "World".
     *
     * @param argv[]	String command line arguments.
     */

    public static void main( String argv[] ) {
	String name = argv.length > 0 ? argv[0] : "World";
	System.out.println( "Hello, " + name + "|" );
    }

}

// ex: set textwidth=72 :
