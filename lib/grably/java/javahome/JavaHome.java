public class JavaHome {
  public static void main(String[] args) {
    System.out.println(System.getProperty("java.home"));
    System.out.println(Object.class.getPackage().getSpecificationVersion());
  }
}
