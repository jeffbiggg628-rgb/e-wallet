package tw.ewallet.wallet.ping.internal;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

/** Schema smoke query proving the DataSource → MyBatis → Flyway-migrated schema path works. */
@Mapper
public interface SmokeMapper {

  @Select("SELECT COUNT(*) FROM accounts")
  long countAccounts();
}
