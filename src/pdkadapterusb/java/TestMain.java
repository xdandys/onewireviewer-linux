import com.dalsemi.onewire.adapter.DSPortAdapter;
import com.dalsemi.onewire.utils.Convert;

public class TestMain 
{
	public static void main(String[] args)
	   throws Exception
	{
		com.dalsemi.onewire.adapter.PDKAdapterUSB pdk = 
			new com.dalsemi.onewire.adapter.PDKAdapterUSB();
		System.out.println("select port returned: " + pdk.selectPort("USB1"));
      System.out.println("adapterDetected returned: " + pdk.adapterDetected());
		System.out.println("reset returned: " + pdk.reset());
		byte[] buff = new byte[] { 0x33, (byte)0xFF, (byte)0xFF, (byte)0xFF, (byte)0xFF
				, (byte)0xFF, (byte)0xFF, (byte)0xFF, (byte)0xFF
		};
		pdk.dataBlock(buff, 0, 9);
		System.out.println("datablock returned: " + Convert.toHexString(buff));

      System.out.println("reset returned: " + pdk.reset());
      pdk.putByte(0x33);
      System.out.println("getByte returned: " + Convert.toHexString((byte)pdk.getByte()));
      System.out.println("getByte returned: " + Convert.toHexString((byte)pdk.getByte()));

      System.out.println("reset returned: " + pdk.reset());
      pdk.putBit(true);
      pdk.putBit(true);
      pdk.putBit(false);
      pdk.putBit(false);
      pdk.putBit(true);
      pdk.putBit(true);
      pdk.putBit(false);
      pdk.putBit(false);
      byte b = 0;
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      b = (byte)((b<<1) | (pdk.getBit()?1:0));
      System.out.println("getBit returned: " + Convert.toHexString(b));

      System.out.println("find first: " + pdk.findFirstDevice());
      System.out.println("address: " + pdk.getAddressAsString());
      while(pdk.findNextDevice())
         System.out.println("address: " + pdk.getAddressAsString());
      
      System.out.println("powerdelivery: " + pdk.startPowerDelivery(DSPortAdapter.CONDITION_NOW));
      pdk.setPowerNormal();
      System.out.println("powerdelivery after bit: " + pdk.startPowerDelivery(DSPortAdapter.CONDITION_AFTER_BIT));
      pdk.setPowerNormal();
      System.out.println("powerdelivery after byte: " + pdk.startPowerDelivery(DSPortAdapter.CONDITION_AFTER_BYTE));
      pdk.setPowerNormal();
         
      
      pdk.freePort();

	}

}
