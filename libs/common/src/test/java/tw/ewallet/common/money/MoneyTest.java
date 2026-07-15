package tw.ewallet.common.money;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class MoneyTest {

  @Test
  void holdsAmountInMinorUnits() {
    Money money = new Money(1_000L, "TWD");
    assertEquals(1_000L, money.minorUnits());
    assertEquals("TWD", money.currency());
  }

  @Test
  void rejectsBlankCurrency() {
    assertThrows(IllegalArgumentException.class, () -> new Money(100L, " "));
  }
}
