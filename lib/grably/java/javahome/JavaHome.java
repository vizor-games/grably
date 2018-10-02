public class JavaHome {
  public static void main(String[] args) {
    System.out.println("java.home:" + System.getProperty("java.home"));
    String specVersion =
    	System.getProperty("java.specification.version", Object.class.getPackage().getSpecificationVersion());
    System.out.println("java.specification.version:" + specVersion);
  }
}
