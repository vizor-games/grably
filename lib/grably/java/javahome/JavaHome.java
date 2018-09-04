public class JavaHome {
  public static void main(String[] args) {
    System.out.println(System.getProperty("java.home"));
    String specVersion =
    	System.getProperty("java.specification.version", Object.class.getPackage().getSpecificationVersion());
    System.out.println(specVersion);
  }
}
