package tw.ewallet.common.money;

/**
 * Monetary amount expressed in integer minor units (plan §4: floating point is forbidden on money
 * paths). Skeleton only — arithmetic and currency rules arrive in Phase 1.
 */
public record Money(long minorUnits, String currency) {

  public Money {
    if (currency == null || currency.isBlank()) {
      throw new IllegalArgumentException("currency must not be blank");
    }
  }
}
