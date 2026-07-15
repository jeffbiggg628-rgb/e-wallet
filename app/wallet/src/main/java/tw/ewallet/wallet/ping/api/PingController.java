package tw.ewallet.wallet.ping.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Liveness probe endpoint. Also the smallest example of the module layout convention: cross-module
 * imports may only target another module's {@code api} package, never {@code internal}.
 */
@RestController
@RequestMapping("/api/v1")
public class PingController {

  public record PingResponse(String status) {}

  @GetMapping("/ping")
  public PingResponse ping() {
    return new PingResponse("ok");
  }
}
