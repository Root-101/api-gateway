package dev.root101.api_gateway.feature.data.jpa;

import dev.root101.api_gateway.feature.data.entity.RouteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RouteJpaRepo extends JpaRepository<RouteEntity, Integer> {

    RouteEntity findByName(String name);

}
