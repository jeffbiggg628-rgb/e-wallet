package tw.ewallet.wallet;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import tw.ewallet.wallet.ping.internal.SmokeMapper;

/**
 * Boots the full application context against a real MySQL 8 container: Flyway must migrate the
 * baseline schema and MyBatis must be able to query it.
 */
@SpringBootTest
@Testcontainers
class SchemaSmokeIT {

  @Container @ServiceConnection
  static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

  @Autowired private SmokeMapper smokeMapper;

  @Test
  void flywayMigratesBaselineSchemaAndMyBatisCanQueryIt() {
    assertThat(smokeMapper.countAccounts()).isZero();
  }
}
